import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/metartpay_branding.dart';
import '../../providers/merchant_provider.dart';

class WalletGenerationStep extends StatefulWidget {
  final Map<String, dynamic> setupData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const WalletGenerationStep({
    Key? key,
    required this.setupData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<WalletGenerationStep> createState() => _WalletGenerationStepState();
}

class _WalletGenerationStepState extends State<WalletGenerationStep> {
  bool _isGenerating = false;
  Map<String, String> _walletAddresses = {};

  List<Map<String, dynamic>> _cryptoNetworks = [];

  @override
  void initState() {
    super.initState();
    _walletAddresses = Map<String, String>.from(
      widget.setupData['walletAddresses'] ?? {}
    );
    
    // Get crypto networks from provider
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    _cryptoNetworks = merchantProvider.getWalletNetworks();
    
    // Auto-generate wallets if not already done
    if (_walletAddresses.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateWallets();
      });
    }
  }

  Future<void> _generateWallets() async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate wallet generation
    await Future.delayed(const Duration(seconds: 3));

    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final generatedAddresses = merchantProvider.generateWalletAddresses();

    setState(() {
      _walletAddresses = generatedAddresses;
      _isGenerating = false;
    });

    widget.onDataUpdate('walletAddresses', _walletAddresses);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crypto wallets generated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleNext() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Crypto Wallet Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: MetartPayColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll generate secure wallet addresses for receiving crypto payments.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: _isGenerating
                ? _buildGeneratingState()
                : _buildWalletsGenerated(),
          ),

          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: MetartPayColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: MetartPayColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: MetartPayButton(
                  text: 'Continue',
                  onPressed: _walletAddresses.isNotEmpty ? _handleNext : null,
                  isGradient: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Column(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(MetartPayColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Generating Wallets...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MetartPayColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait while we create secure wallet addresses for your crypto payments.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildWalletsGenerated() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Success Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallets Generated Successfully!',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your crypto wallet addresses are ready to receive payments.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Wallet Networks with Tokens
          ..._cryptoNetworks.map((network) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Header
                  Row(
                    children: [
                      Text(
                        network['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              network['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              network['description'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tokens for this network
                  ...network['tokens'].map<Widget>((token) {
                    final address = _walletAddresses[token['key']] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(network['color']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  token['symbol'],
                                  style: TextStyle(
                                    color: Color(network['color']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  token['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _copyAddress(address),
                                icon: const Icon(Icons.copy, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Copy address',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            address,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These wallet addresses are yours to keep. You can view and share them anytime from your dashboard.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}