import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../providers/merchant_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = true;
  List<Merchant> _merchants = [];
  // Track processing merchant ids to disable buttons while an action runs
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    setState(() => _loading = true);
    String? _errorMsg;
    try {
      final data = await _firebaseService.getMerchantsForKycReview();
      if (!mounted) return;
      setState(() {
        _merchants = data;
      });
    } catch (e) {
      // Surface helpful error messages (index or permission issues)
      final msg = e.toString();
      debugPrint('Admin load merchants error: $msg');
      _errorMsg = _shortenError(msg);
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (_errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load merchants: ${_errorMsg}')));
    }
  }

  Future<void> _updateKyc(String merchantId, String status) async {
    setState(() => _processing.add(merchantId));
    try {
      await _firebaseService.updateMerchantKycStatus(merchantId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KYC status updated to $status')),
      );
      await _loadMerchants();
    } catch (e) {
      final msg = e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update KYC: ${_shortenError(msg)}')),
      );
    } finally {
      setState(() => _processing.remove(merchantId));
    }
  }

  Future<void> _updateKycWithReason(String merchantId, String status, {String? reason}) async {
    setState(() => _processing.add(merchantId));
    try {
      await _firebaseService.updateMerchantKycStatus(merchantId, status, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KYC status updated to $status')),
      );
      await _loadMerchants();
    } catch (e) {
      final msg = e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update KYC: ${_shortenError(msg)}')),
      );
    } finally {
      setState(() => _processing.remove(merchantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMerchants,
              child: Builder(builder: (context) {
                // Merge remote list with current merchant (if admin is viewing their own pending KYC)
                final providerMerchant = Provider.of<MerchantProvider>(context, listen: false).currentMerchant;
                final displayList = List<Merchant>.from(_merchants);
                if (providerMerchant != null) {
                  final status = providerMerchant.kycStatus.toLowerCase();
                  if ((status == 'pending' || status == 'under-review') && !_merchants.any((m) => m.id == providerMerchant.id)) {
                    displayList.insert(0, providerMerchant);
                  }
                }

                if (displayList.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No merchants pending KYC review')),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = displayList[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Owner: ${m.fullName}'),
                            const SizedBox(height: 6),
                            Text('KYC: ${m.kycStatus}'),
                            const SizedBox(height: 8),
                            // Use Wrap so buttons wrap instead of causing overflow
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: _processing.contains(m.id) ? null : () => _updateKyc(m.id, 'verified'),
                                  child: _processing.contains(m.id) ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: _processing.contains(m.id) ? null : () => _showRejectDialog(m),
                                  child: const Text('Reject'),
                                ),
                                TextButton(
                                  onPressed: _processing.contains(m.id) ? null : () => _updateKycWithReason(m.id, 'under-review'),
                                  child: const Text('Mark Under Review'),
                                ),
                                TextButton(
                                  onPressed: () => _showMerchantDetails(m),
                                  child: const Text('Details'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
    );
  }


  String _shortenError(String full) {
    // If Firestore suggests creating an index, capture the URL or a short hint
    if (full.contains('requires an index')) {
      final uriStart = full.indexOf('https://');
      if (uriStart != -1) {
        final uri = full.substring(uriStart).split(RegExp(r'\s')).first;
        return 'Query requires an index. Create it: $uri';
      }
      return 'Query requires a Firestore index (see console)';
    }
    if (full.contains('PERMISSION_DENIED') || full.toLowerCase().contains('permission')) {
      return 'Missing or insufficient Firestore permissions. Check rules or authenticate as admin.';
    }
    // Otherwise return a truncated message
    return full.length > 120 ? '${full.substring(0, 120)}...' : full;
  }
  void _showMerchantDetails(Merchant m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Owner: ${m.fullName}'),
                const SizedBox(height: 8),
                Text('Email: ${m.contactEmail}'),
                const SizedBox(height: 8),
                if (m.idNumber != null) Text('ID: ${m.idNumber}'),
                if (m.bvn != null) Text('BVN: ${m.bvn}'),
                const SizedBox(height: 12),
                const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Account: ${m.bankAccountNumber}'),
                Text('Bank: ${m.bankName}'),
                Text('Account Name: ${m.bankAccountName}'),
                const SizedBox(height: 12),
                const Text('Wallet Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (m.walletAddresses.isEmpty) const Text('No wallet addresses provided'),
                ...m.walletAddresses.entries.map((e) => Text('${e.key}: ${e.value}')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(Merchant m) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateKycWithReason(m.id, 'rejected', reason: controller.text.trim().isEmpty ? null : controller.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
