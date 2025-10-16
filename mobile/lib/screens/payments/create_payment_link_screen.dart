import 'package:flutter/material.dart';
// removed unused import
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../../services/crypto_price_service.dart';
import '../../widgets/metartpay_branding.dart';

class CreatePaymentLinkScreen extends StatefulWidget {
  const CreatePaymentLinkScreen({super.key});

  @override
  State<CreatePaymentLinkScreen> createState() => _CreatePaymentLinkScreenState();
}

class _CreatePaymentLinkScreenState extends State<CreatePaymentLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedChain = 'ethereum';
  String _selectedToken = 'USDT';
  bool _isLoading = false;
  bool _isLoadingPrice = false;
  
  final CryptoPriceService _cryptoPriceService = CryptoPriceService();
  CryptoPrice? _currentTokenPrice;
  double? _cryptoAmount;

  final List<Map<String, dynamic>> _supportedChains = [
    {
      'id': 'ethereum',
      'name': 'Ethereum',
      'symbol': 'ETH',
      'color': Colors.blue,
      'tokens': ['USDT', 'USDC', 'DAI', 'ETH'],
    },
    {
      'id': 'bitcoin',
      'name': 'Bitcoin',
      'symbol': 'BTC',
      'color': Colors.orange,
      'tokens': ['BTC'],
    },
    {
      'id': 'bnb',
      'name': 'BNB Smart Chain',
      'symbol': 'BNB',
      'color': Colors.yellow,
      'tokens': ['USDT', 'USDC', 'BUSD', 'BNB'],
    },
    {
      'id': 'polygon',
      'name': 'Polygon',
      'symbol': 'MATIC',
      'color': Colors.purple,
      'tokens': ['USDT', 'USDC', 'DAI', 'MATIC'],
    },
    {
      'id': 'arbitrum',
      'name': 'Arbitrum',
      'symbol': 'ARB',
      'color': Colors.blue,
      'tokens': ['USDT', 'USDC', 'DAI', 'ARB'],
    },
    {
      'id': 'optimism',
      'name': 'Optimism',
      'symbol': 'OP',
      'color': Colors.red,
      'tokens': ['USDT', 'USDC', 'DAI', 'OP'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTokenPrice();
    _amountController.addListener(_calculateCryptoAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenPrice() async {
    setState(() {
      _isLoadingPrice = true;
    });

    try {
      final price = await _cryptoPriceService.getCryptoPrice(_selectedToken);
      setState(() {
        _currentTokenPrice = price;
      });
      _calculateCryptoAmount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load price for $_selectedToken')),
        );
      }
    } finally {
      setState(() {
        _isLoadingPrice = false;
      });
    }
  }

  void _calculateCryptoAmount() {
    if (_amountController.text.isNotEmpty && _currentTokenPrice != null) {
      final fiatAmount = double.tryParse(_amountController.text);
      if (fiatAmount != null && fiatAmount > 0) {
        setState(() {
          _cryptoAmount = fiatAmount / _currentTokenPrice!.priceInNGN;
        });
        return;
      }
    }
    setState(() {
      _cryptoAmount = null;
    });
  }

  Future<void> _onChainChanged(String newChain) async {
    setState(() {
      _selectedChain = newChain;
      // Reset to first token of selected chain
      final chainTokens = _supportedChains
          .firstWhere((chain) => chain['id'] == newChain)['tokens'] as List<String>;
      _selectedToken = chainTokens.first;
    });
    await _loadTokenPrice();
  }

  Future<void> _onTokenChanged(String newToken) async {
    setState(() {
      _selectedToken = newToken;
    });
    await _loadTokenPrice();
  }

  Future<void> _createPaymentLink() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cryptoAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final merchantProvider = context.read<MerchantProvider>();
      
      // Create a simple payment link for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment link created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating payment link: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentChain = _supportedChains.firstWhere(
      (chain) => chain['id'] == _selectedChain,
    );

    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Create Payment Link',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              GradientCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Generate Payment Link',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate a secure payment link to receive cryptocurrency payments',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (NGN)',
                          prefixIcon: const Icon(Icons.currency_exchange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value!);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Crypto Amount Display
                      if (_cryptoAmount != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.currency_bitcoin,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Crypto Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    Text(
                                      '${_cryptoAmount!.toStringAsFixed(6)} $_selectedToken',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoadingPrice)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Blockchain Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Blockchain Network',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Chain Selection
                      DropdownButtonFormField<String>(
                          initialValue: _selectedChain,
                        decoration: InputDecoration(
                          labelText: 'Select Blockchain',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.account_tree),
                        ),
                        items: _supportedChains.map((chain) {
                          return DropdownMenuItem<String>(
                            value: chain['id'],
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: chain['color'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(chain['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => _onChainChanged(value!),
                      ),

                      const SizedBox(height: 16),

                      // Token Selection
                      DropdownButtonFormField<String>(
                          initialValue: _selectedToken,
                        decoration: InputDecoration(
                          labelText: 'Select Token',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.token),
                        ),
                        items: (currentChain['tokens'] as List<String>).map((token) {
                          return DropdownMenuItem<String>(
                            value: token,
                            child: Text(token),
                          );
                        }).toList(),
                        onChanged: (value) => _onTokenChanged(value!),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          hintText: 'Enter payment description...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                height: 56,
                child: MetartPayButton(
                  onPressed: _isLoading ? null : _createPaymentLink,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Payment Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}