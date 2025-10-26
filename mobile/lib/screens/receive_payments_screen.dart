import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/wallet_address.dart';
import '../models/models.dart' as models;
import '../services/wallet_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_logger.dart';
import '../providers/merchant_provider.dart';

class ReceivePaymentsScreen extends StatefulWidget {
  final String merchantId;
  const ReceivePaymentsScreen({super.key, required this.merchantId});
  @override
  State<ReceivePaymentsScreen> createState() => _ReceivePaymentsScreenState();
}

class _ReceivePaymentsScreenState extends State<ReceivePaymentsScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String selectedNetwork = 'ETH';
  String selectedToken = 'USDT';
  List<WalletAddress> wallets = [];
  bool isLoading = false;
  String? currentPaymentLink;
  bool nfcAvailable = false;
  bool isNFCWriting = false;
  String _qrPayload = '';
  StreamSubscription<List<models.Transaction>>? _txSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureQuickReceive());
  }

  Future<void> _ensureQuickReceive() async {
    setState(() => isLoading = true);
    try {
      final merchantId = widget.merchantId;
      final svc = FirebaseService();
      final merchant = await svc.getMerchant(merchantId);
      Map<String, String> walletsMap = {};

      if (merchant == null || (merchant.walletAddresses.isEmpty ?? true)) {
        walletsMap = await svc.generateAndSaveMerchantWallets(merchantId);
      } else {
        walletsMap = merchant.walletAddresses;
      }

      final address = walletsMap[selectedNetwork] ?? '';
      if (address.isNotEmpty) {
        _qrPayload =
            'pay:$address?token=$selectedToken&network=$selectedNetwork';

        _txSub?.cancel();
        _txSub = svc.watchMerchantTransactions(merchantId).listen((txs) {
          for (final t in txs) {
            try {
              if (t.toAddress == address && t.status == 'paid') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment received: ₦${t.amountNaira}'),
                  ),
                );
              }
            } catch (_) {}
          }
        });
      }
    } catch (e, st) {
      AppLogger.e('Quick receive setup failed: $e', error: e, stackTrace: st);
    } finally {
      setState(() => isLoading = false);
    }
  }

  final List<Map<String, dynamic>> supportedNetworks = [
    {
      'code': 'ETH',
      'name': 'Ethereum',
      'tokens': ['USDT', 'USDC'],
      'icon': '⟠',
      'color': Colors.blue,
    },
    {
      'code': 'BTC',
      'name': 'Bitcoin',
      'tokens': ['BTC'],
      'icon': '₿',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedNetworkData = supportedNetworks.firstWhere(
      (n) => n['code'] == selectedNetwork,
    );
    final wallet = wallets.firstWhere(
      (w) => w.network == selectedNetwork,
      orElse: () => WalletAddress(
        network: selectedNetwork,
        address: '',
        id: '',
        merchantId: widget.merchantId,
        createdAt: DateTime.now(),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receive Payment',
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Receive (static QR/address for in-person payments)
                  _buildSectionCard(
                    title: 'Quick Receive (in-person)',
                    child: Column(
                      children: [
                        if (_qrPayload.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/qr-view-v2',
                                arguments: {
                                  'payload': _qrPayload,
                                  'network': selectedNetwork,
                                  'token': selectedToken,
                                  'crypto': 0.0,
                                  'merchantId': widget.merchantId,
                                  'paymentId': null,
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  QrImageView(
                                    data: _qrPayload,
                                    version: QrVersions.auto,
                                    size: 220,
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
                                  Image.asset(
                                    'assets/icons/app logo qr.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_qrPayload.isEmpty) return;
                                  await Clipboard.setData(
                                    ClipboardData(text: _qrPayload),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied payment payload'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_qrPayload.isEmpty) return;
                                  try {
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        text: _qrPayload,
                                        subject: 'Payment Request',
                                      ),
                                    );
                                  } catch (e) {
                                    AppLogger.e('Share failed: $e', error: e);
                                  }
                                },
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for payment...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Select Network',
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 3,
                              ),
                          itemCount: supportedNetworks.length,
                          itemBuilder: (context, index) {
                            final network = supportedNetworks[index];
                            final isSelected =
                                selectedNetwork == network['code'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedNetwork = network['code'];
                                  final tokens =
                                      network['tokens'] as List<String>;
                                  if (!tokens.contains(selectedToken)) {
                                    selectedToken = tokens.first;
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      network['icon'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      network['code'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ...List<Widget>.from(
                              (selectedNetworkData['tokens'] as List<String>)
                                  .map((token) {
                                    final isSelected = selectedToken == token;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => selectedToken = token,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              token,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? colorScheme.onPrimary
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (wallet.address.isNotEmpty)
                    _buildSectionCard(
                      title: '  Address',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedNetworkData['icon'],
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: isLoading
                                            ? Colors.grey
                                            : colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        wallet.address,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (wallet.address.isEmpty) return;
                                    await Clipboard.setData(
                                      ClipboardData(text: wallet.address),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied address'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (currentPaymentLink != null)
                    _buildSectionCard(
                      title: 'Payment QR Code',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: currentPaymentLink!,
                                  version: QrVersions.auto,
                                  size: 200,
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
                                Image.asset(
                                  'assets/icons/app logo qr.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Link'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Share'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (currentPaymentLink != null && nfcAvailable)
                    _buildSectionCard(
                      title: 'NFC Tap-to-Pay',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withAlpha(
                                (0.08 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.secondary),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.nfc,
                                  color: colorScheme.secondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NFC Ready',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                      Text(
                                        'Tap-to-pay is ready to use',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.nfc, size: 18),
                                  label: const Text('Write NFC Tag'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.tertiary,
                                    foregroundColor: colorScheme.onTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withAlpha(
                                (0.12 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colorScheme.secondary.withAlpha(
                                  (0.28 * 255).round(),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📱 How to use NFC:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Write NFC Tag: Program a physical NFC tag/card for your shop\n'
                                  '• Customer taps their phone on the NFC tag to pay',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withAlpha((0.85 * 255).round()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _txSub?.cancel();
    super.dispose();
  }
}
