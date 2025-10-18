import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/crypto_wallet_service.dart';
import '../../providers/payment_link_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../utils/app_logger.dart';

class CreatePaymentLinkScreen extends StatefulWidget {
  const CreatePaymentLinkScreen({super.key});

  @override
  State<CreatePaymentLinkScreen> createState() => _CreatePaymentLinkScreenState();
}

class _CreatePaymentLinkScreenState extends State<CreatePaymentLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // System-wide supported networks/tokens (merchant cannot change)
  final List<String> _availableNetworks = ['BTC', 'ETH', 'BSC', 'SOL'];
  // Map tokens per network to avoid showing invalid combos (e.g., BTC USDT)
  final Map<String, List<String>> _networkTokens = {
    'BTC': ['BTC'],
    'ETH': ['ETH', 'USDT', 'USDC'],
    'BSC': ['BNB', 'USDT', 'BUSD'],
    'SOL': ['SOL', 'USDT', 'USDC'],
  };

  // Aggregated list of unique tokens across networks (preserves first-seen order)
  List<String> get _availableTokens {
    final seen = <String>{};
    final out = <String>[];
    for (final tokens in _networkTokens.values) {
      for (final t in tokens) {
        if (seen.add(t)) out.add(t);
      }
    }
    return out;
  }
  
  DateTime? _expiryDate;
  bool _hasExpiry = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Create Payment Link'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<PaymentLinkProvider>(
        builder: (context, paymentLinkProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard(
                  title: 'Payment Information',
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Payment Title *',
                        hintText: 'e.g., "Product Purchase", "Service Payment"',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a payment title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Additional details about this payment',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (NGN) *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.money),
                        prefixText: '₦ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Accepted Networks',
                  children: [
                    const Text(
                      'Supported networks (system-wide). Buyers will choose their preferred network at checkout:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableNetworks.map((network) {
                        return Chip(
                          label: Text(_getNetworkDisplayName(network)),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Accepted Tokens',
                  children: [
                    const Text(
                      'Supported stablecoins (system-wide):',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTokens.map((token) {
                        return Chip(
                          label: Text(token),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Expiration (Optional)',
                  children: [
                    SwitchListTile(
                      title: const Text('Set expiration date'),
                      subtitle: const Text('Payment link will expire automatically'),
                      value: _hasExpiry,
                      onChanged: (value) {
                        setState(() {
                          _hasExpiry = value;
                          if (!value) {
                            _expiryDate = null;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_hasExpiry) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _expiryDate == null
                                      ? 'Select expiration date'
                                      : 'Expires: ${_formatDate(_expiryDate!)}',
                                  style: TextStyle(
                                    color: _expiryDate == null ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreview(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Preview updates as you type. Creating the link may take a few seconds.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha((0.7 * 255).round())),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createPaymentLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create Payment Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
                    Theme.of(context).colorScheme.secondary.withAlpha((0.1 * 255).round()),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _titleController.text.isEmpty ? 'Payment Title' : _titleController.text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _titleController.text.isEmpty ? Colors.grey : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_descriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _descriptionController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '₦${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _availableNetworks.expand((network) {
                      final tokens = _networkTokens[network] ?? [network];
                      return tokens.map((token) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withAlpha((0.12 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.secondary.withAlpha((0.28 * 255).round())),
                          ),
                          child: Text(
                            '$network $token',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                  if (_hasExpiry && _expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expires ${_formatDate(_expiryDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNetworkDisplayName(String network) {
    switch (network) {
      case 'BTC':
        return 'Bitcoin';
      case 'ETH':
        return 'Ethereum';
      case 'BSC':
        return 'Binance Smart Chain';
      case 'MATIC':
        return 'Polygon';
      case 'SOL':
        return 'Solana';
      default:
        return network;
    }
  }
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() {
        _expiryDate = selected;
      });
    }
  }

  Future<void> _createPaymentLink() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasExpiry && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiration date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Show modal progress indicator so user knows work is in progress
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

      final currentMerchant = merchantProvider.currentMerchant;
      if (currentMerchant == null) throw Exception('No merchant selected');

      // Additional validation: require description (per business requirement)
      if (_descriptionController.text.trim().isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a description for the payment link.'), backgroundColor: Colors.orange));
        return;
      }

      // KYC check: allow creation if KYC is verified or pending (business rule)
      final kyc = (currentMerchant.kycStatus ?? '').toLowerCase();
      if (!(kyc == 'verified' || kyc == 'pending')) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC is required before creating payment links. Please complete merchant verification.'), backgroundColor: Colors.red));
        return;
      }

      // Auto-generate and persist wallet addresses if missing
      if (currentMerchant.walletAddresses.isEmpty) {
        AppLogger.d('DEBUG: No wallet addresses found for merchant ${currentMerchant.id}, generating now');
        // Generate wallets off the UI thread to avoid jank
        final generated = await compute(computeGenerateWalletAddresses, {
          'merchantId': currentMerchant.id,
          'userId': currentMerchant.userId,
        });

        AppLogger.d('DEBUG: Generated wallet addresses: ${generated.keys.toList()}');

        final ok = await merchantProvider.updateMerchantSetup(walletAddresses: generated);
        AppLogger.d('DEBUG: updateMerchantSetup returned: $ok');
        if (!ok) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate wallets for merchant. Complete onboarding or try again.'), backgroundColor: Colors.red));
          return;
        }

        // updateMerchantSetup sets _currentMerchant to the saved merchant,
        // so read currentMerchant directly instead of reloading all merchants
        final reloaded = merchantProvider.currentMerchant;
        if (reloaded == null || reloaded.walletAddresses.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merchants wallet not generated yet. Please complete onboarding or try again.'), backgroundColor: Colors.red));
          return;
        }
      }

      // Try to create the payment link with retries and sensible fallbacks
      Map<String, dynamic>? result;
      String? lastError;
      const int maxAttempts = 3;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        result = await paymentLinkProvider.createPaymentLink(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          networks: _availableNetworks,
          tokens: _availableTokens,
          expiresAt: _expiryDate,
        );

        if (result != null) break;

        lastError = paymentLinkProvider.error?.toLowerCase();

        // If backend claims wallets are missing, try to (re)generate and persist once
        if (lastError != null && lastError.contains('wallet') && lastError.contains('not generated')) {
          // regenerate wallets off UI thread
          final generated = await compute(computeGenerateWalletAddresses, {
            'merchantId': currentMerchant.id,
            'userId': currentMerchant.userId,
          });
          final ok = await merchantProvider.updateMerchantSetup(walletAddresses: generated);
          if (!ok) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to persist generated wallets. Please complete onboarding.'), backgroundColor: Colors.red));
            break; // don't keep retrying
          }

          // short delay and retry
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // If backend indicates permission/index problems, save pending link locally and bail
        if (lastError != null && (lastError.contains('permission') || lastError.contains('permission-denied') || lastError.contains('requires an index') || lastError.contains('index'))) {
          await _savePendingLinkLocally(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            networks: _availableNetworks,
            tokens: _availableTokens,
            expiresAt: _expiryDate,
          );
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment link saved locally. Please fix backend permissions/indexes and retry.'), backgroundColor: Colors.orange));
          result = null;
          break;
        }

        // transient error: backoff and retry
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }

      if (result != null) {
        if (!mounted) return;

        // Resolve a shareable URL
        String shareUrl = '';
        final linkId = result['id'] ?? result['linkId'] ?? (result['data'] is Map ? result['data']['id'] : null);
        if (linkId != null) {
          shareUrl = paymentLinkProvider.getPaymentUrl(linkId);
        } else if (result['url'] != null) {
          shareUrl = result['url'];
        } else if (result['link'] != null) {
          shareUrl = result['link'];
        }

        // Show link + QR bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Payment Link Created', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (shareUrl.isNotEmpty) ...[
                    SelectableText(shareUrl),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Link'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Use SharePlus.instance.share with ShareParams
                            SharePlus.instance.share(ShareParams(text: shareUrl));
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: shareUrl,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Image.asset('assets/icons/app logo qr.png', width: 28, height: 28, fit: BoxFit.contain),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text('Created, but could not determine share URL.'),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      } else {
        // If we fell out without a result, show a generic error (detailed errors preserved in logs)
        final errMsg = paymentLinkProvider.error ?? 'Unable to create payment link. Please try again later.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      // Dismiss progress dialog if still shown
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePendingLinkLocally({
    required String title,
    String? description,
    required double amount,
    required List<String> networks,
    required List<String> tokens,
    DateTime? expiresAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pending_payment_links';
      final existing = prefs.getStringList(key) ?? <String>[];
      final payload = json.encode({
        'title': title,
        'description': description,
        'amount': amount,
        'networks': networks,
        'tokens': tokens,
        'expiresAt': expiresAt?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      existing.add(payload);
      await prefs.setStringList(key, existing);
      AppLogger.d('Saved pending payment link locally (count=${existing.length})');
    } catch (e) {
      AppLogger.e('Failed to save pending link locally: $e', error: e);
    }
  }
}