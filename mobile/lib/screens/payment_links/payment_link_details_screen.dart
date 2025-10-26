import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../providers/payment_link_provider.dart';

class PaymentLinkDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> paymentLink;

  const PaymentLinkDetailsScreen({super.key, required this.paymentLink});

  @override
  State<PaymentLinkDetailsScreen> createState() =>
      _PaymentLinkDetailsScreenState();
}

class _PaymentLinkDetailsScreenState extends State<PaymentLinkDetailsScreen> {
  String? _selectedNetwork;
  String? _selectedToken;
  Map<String, dynamic>? _qrCodeData;
  bool _isGeneratingQR = false;

  @override
  void initState() {
    super.initState();
    final cryptoOptions = List.from(widget.paymentLink['cryptoOptions'] ?? []);
    if (cryptoOptions.isNotEmpty) {
      final firstOption = cryptoOptions.first;
      _selectedNetwork = firstOption['network'];
      _selectedToken = firstOption['token'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateQRCode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.paymentLink['amount']?.toDouble() ?? 0.0;
    final status = widget.paymentLink['status'] ?? 'unknown';
    final cryptoOptions = List.from(widget.paymentLink['cryptoOptions'] ?? []);
    final currentOption = cryptoOptions.firstWhere(
      (opt) =>
          opt['network'] == _selectedNetwork && opt['token'] == _selectedToken,
      orElse: () => cryptoOptions.isNotEmpty ? cryptoOptions.first : null,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Link'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePaymentLink,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(Icons.toggle_on),
                    SizedBox(width: 8),
                    Text('Toggle Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'toggle_status':
                  _toggleStatus();
                  break;
                case 'copy_link':
                  _copyLink();
                  break;
                case 'delete':
                  _deletePaymentLink();
                  break;
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPaymentInfoCard(amount, status),
          const SizedBox(height: 16),
          if (cryptoOptions.length > 1) _buildNetworkSelector(cryptoOptions),
          if (cryptoOptions.length > 1) const SizedBox(height: 16),
          _buildQRCodeCard(currentOption),
          const SizedBox(height: 16),
          _buildPaymentDetailsCard(currentOption),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(double amount, String status) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.paymentLink['title'] ?? 'Payment Link',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (widget.paymentLink['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.paymentLink['description'],
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '₦${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusChip(status),
            if (widget.paymentLink['expiresAt'] != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${_formatDate(DateTime.parse(widget.paymentLink['expiresAt']))}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSelector(List cryptoOptions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cryptoOptions.map<Widget>((option) {
                final network = option['network'];
                final token = option['token'];
                final isSelected =
                    _selectedNetwork == network && _selectedToken == token;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedNetwork = network;
                      _selectedToken = token;
                    });
                    _generateQRCode();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$network $token',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(Map<String, dynamic>? currentOption) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Scan to Pay',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isGeneratingQR
                  ? const Center(child: CircularProgressIndicator())
                  : _qrCodeData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_qrCodeData!['qrCode'].split(',')[1]),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.qr_code, size: 64, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 16),
            if (currentOption != null) ...[
              Text(
                'Send ${currentOption['amount']} ${currentOption['token']}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'on ${_getNetworkDisplayName(currentOption['network'])}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(Map<String, dynamic>? currentOption) {
    if (currentOption == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Network',
              _getNetworkDisplayName(currentOption['network']),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Token', currentOption['token']),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Amount',
              '${currentOption['amount']} ${currentOption['token']}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Wallet Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                currentOption['address'],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: currentOption['address']),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalPayments = widget.paymentLink['totalPayments'] ?? 0;
    final totalAmount =
        widget.paymentLink['totalAmountReceived']?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Payments',
                    totalPayments.toString(),
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Amount Received',
                    '₦${totalAmount.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Active';
        icon = Icons.check_circle;
        break;
      case 'inactive':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'Inactive';
        icon = Icons.pause_circle;
        break;
      case 'expired':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Expired';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        label = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getNetworkDisplayName(String network) {
    switch (network) {
      case 'ETH':
        return 'Ethereum';
      case 'BSC':
        return 'Binance Smart Chain';
      case 'MATIC':
        return 'Polygon';
      default:
        return network;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generateQRCode() async {
    if (_selectedNetwork == null || _selectedToken == null) return;

    setState(() {
      _isGeneratingQR = true;
    });

    try {
      final paymentLinkProvider = Provider.of<PaymentLinkProvider>(
        context,
        listen: false,
      );
      final result = await paymentLinkProvider.generateQRCode(
        widget.paymentLink['id'],
        network: _selectedNetwork!,
        token: _selectedToken!,
      );

      if (!mounted) return;
      if (result != null) {
        setState(() {
          _qrCodeData = result;
        });
      }
    } catch (e) {
      debugPrint('Error generating QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQR = false;
        });
      }
    }
  }

  void _sharePaymentLink() {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(
      context,
      listen: false,
    );
    final url = paymentLinkProvider.getPaymentUrl(
      widget.paymentLink['id'],
      network: _selectedNetwork,
      token: _selectedToken,
    );

    SharePlus.instance.share(
      ShareParams(
        text:
            'Pay ${widget.paymentLink['title']} - \u20a6${widget.paymentLink['amount']}\n\n$url',
        subject: 'Payment Request - ${widget.paymentLink['title']}',
      ),
    );
  }

  void _copyLink() {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(
      context,
      listen: false,
    );
    final url = paymentLinkProvider.getPaymentUrl(widget.paymentLink['id']);

    // capture and perform clipboard operation, then use State.context for UI
    Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(
      context,
      listen: false,
    );
    await paymentLinkProvider.togglePaymentLinkStatus(
      widget.paymentLink['id'],
      widget.paymentLink['status'],
    );

    // Update local state
    if (!mounted) return;
    setState(() {
      widget.paymentLink['status'] = widget.paymentLink['status'] == 'active'
          ? 'inactive'
          : 'active';
    });
  }

  Future<void> _deletePaymentLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Payment Link'),
        content: const Text(
          'Are you sure you want to delete this payment link? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final paymentLinkProvider = Provider.of<PaymentLinkProvider>(
        context,
        listen: false,
      );
      await paymentLinkProvider.deletePaymentLink(widget.paymentLink['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }
}
