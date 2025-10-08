import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/wallet_address.dart';
import '../services/wallet_service.dart';

class ReceivePaymentsScreen extends StatefulWidget {
  final String merchantId;
  const ReceivePaymentsScreen({Key? key, required this.merchantId}) : super(key: key);
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
    final selectedNetworkData = supportedNetworks.firstWhere((n) => n['code'] == selectedNetwork);
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
      appBar: AppBar(title: const Text('Receive Payment')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: 'Payment Details',
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (NGN)',
                            prefixText: '\u20a6 ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.link),
                          label: const Text('Generate Payment Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 3,
                          ),
                          itemCount: supportedNetworks.length,
                          itemBuilder: (context, index) {
                            final network = supportedNetworks[index];
                            final isSelected = selectedNetwork == network['code'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedNetwork = network['code'];
                                  final tokens = network['tokens'] as List<String>;
                                  if (!tokens.contains(selectedToken)) {
                                    selectedToken = tokens.first;
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? network['color'] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? network['color'] : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      network['icon'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      network['code'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.grey[700],
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
                            ...List<Widget>.from((selectedNetworkData['tokens'] as List<String>).map((token) {
                              final isSelected = selectedToken == token;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () => setState(() => selectedToken = token),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blue : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        token,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })),
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
                              color: Colors.grey[100],
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
                                        color: selectedNetworkData['color'],
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
                                  onPressed: () {},
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selectedNetworkData['color'],
                                    foregroundColor: Colors.white,
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
                            child: QrImageView(
                              data: currentPaymentLink!,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
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
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.nfc,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'NFC Ready',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Text(
                                        'Tap-to-pay is ready to use',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
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
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📱 How to use NFC:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Write NFC Tag: Program a physical NFC tag/card for your shop\n'
                                  '• Customer taps their phone on the NFC tag to pay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
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
    super.dispose();
  }
}
