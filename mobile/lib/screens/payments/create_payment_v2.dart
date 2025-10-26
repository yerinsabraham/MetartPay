import 'package:flutter/material.dart';
import '../../widgets/metartpay_branding.dart';
import '../../utils/app_logger.dart';
import '../../controllers/payment_controller_v2.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';

class CreatePaymentV2 extends StatefulWidget {
  const CreatePaymentV2({Key? key}) : super(key: key);

  @override
  State<CreatePaymentV2> createState() => _CreatePaymentV2State();
}

class _CreatePaymentV2State extends State<CreatePaymentV2> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _network = 'BSC';
  String _token = 'USDT';
  bool _autoConvert = true;
  bool _loading = false;
  final PaymentControllerV2 _controller = PaymentControllerV2();
  int _step = 1;
  String? _selectedOptionKey;
  // tokens grid definition for step 2
    final List<Map<String, String>> _tokenOptions = [
    {'key': 'BTC', 'label': 'Bitcoin (BTC)', 'asset': 'assets/icons/bitcoin-logo.png', 'network': 'BTC', 'standard': ''},
    // Solana options: selecting these will immediately create an address-only QR
    {'key': 'SOL', 'label': 'Solana (SOL)', 'asset': 'assets/icons/solana-logo.png', 'network': 'SOL', 'standard': ''},
    {'key': 'USDC_SOL', 'label': 'USDC – Solana', 'asset': 'assets/icons/usdc-logo.png', 'network': 'SOL', 'standard': 'SPL'},
    {'key': 'USDT_SOL', 'label': 'USDT – Solana', 'asset': 'assets/icons/usdt-logo.png', 'network': 'SOL', 'standard': 'SPL'},
    {'key': 'USDT_BSC', 'label': 'USDT – BSC', 'asset': 'assets/icons/usdt-logo.png', 'network': 'BSC', 'standard': 'BEP20'},
    {'key': 'USDT_ETH', 'label': 'USDT – Ethereum', 'asset': 'assets/icons/usdt-logo.png', 'network': 'ETH', 'standard': 'ERC20'},
    {'key': 'USDC_ETH', 'label': 'USDC – Ethereum', 'asset': 'assets/icons/usdc-logo.png', 'network': 'ETH', 'standard': 'ERC20'},
    {'key': 'USDT_TRC', 'label': 'USDT – TRON', 'asset': 'assets/icons/usdt-logo.png', 'network': 'TRC20', 'standard': 'TRC20'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize selected option key from default token/network
    if (_token.isNotEmpty && _network.isNotEmpty) {
      _selectedOptionKey = _token == 'BTC' ? 'BTC' : '${_token}_$_network';
    }

    // Respect route arguments that may preselect a network/token and skip the amount step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      final skip = args['skipAmountStep'] as bool? ?? false;
      final defNet = args['defaultNetwork'] as String?;
      final defTok = args['defaultToken'] as String?;
      if (defNet != null) _network = defNet;
      if (defTok != null) _token = defTok;
      if (_token.isNotEmpty && _network.isNotEmpty) _selectedOptionKey = _token == 'BTC' ? 'BTC' : '${_token}_$_network';
      if (skip) setState(() => _step = 2);
    });

    // Ensure merchant data is loaded so we don't show "No merchant selected" when merchant exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
      if (merchantProvider.currentMerchant == null && !merchantProvider.hasAttemptedLoad) {
        merchantProvider.loadUserMerchants();
      }
    });
  }

  Future<void> _generate({double? amountOverride}) async {
    setState(() => _loading = true);
    try {
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
      final merchantId = merchantProvider.currentMerchant?.id;
      if (merchantId == null || merchantId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No merchant selected. Please set up a merchant first.')));
        return;
      }

      double amount = 0.0;
      if (amountOverride != null) {
        amount = amountOverride;
      } else if (_step == 2 && _amountController.text.isNotEmpty) {
        amount = double.parse(_amountController.text);
      }

      // For Solana selections, create payment without amount so backend returns address-only QR
      final isSol = (_network.toUpperCase().startsWith('SOL') || _network.toUpperCase() == 'SOL');

      final result = await _controller.createPayment(
        merchantId: merchantId,
        amountNgn: isSol ? 0.0 : amount,
        token: _token,
        network: _network,
        description: null,
        autoConvert: _autoConvert,
      );

      final qrPayload = result['qrPayload'] as String? ?? 'placeholder:${result['paymentId'] ?? 'unknown'}';

      AppLogger.d('DEBUG: Generate payment result: $result');

      Navigator.pushNamed(context, '/qr-view-v2', arguments: {
        'network': result['network'] ?? _network,
        'token': result['token'] ?? _token,
        'naira': isSol ? null : amount,
        'crypto': result['cryptoAmount'] ?? 0.0,
        'payload': qrPayload,
        'paymentId': result['paymentId'],
        'merchantId': merchantId,
        'address': result['address'],
      });
    } catch (e, st) {
      AppLogger.e('Failed to generate payment: $e', error: e, stackTrace: st);
      final msg = e?.toString() ?? 'Failed to generate payment';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate payment: ${msg.length > 120 ? msg.substring(0, 120) + "..." : msg}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 1) ...[
                const Text('Step 1 — Choose Token / Network', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: _tokenOptions.map((t) {
                    final key = t['key']!;
                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedOptionKey = key;
                          final parts = key.split('_');
                          if (parts.length == 1) {
                            _token = parts[0];
                            _network = parts[0];
                          } else {
                            _token = parts[0];
                            _network = parts[1];
                          }
                        });

                        // Only select on tile tap. Do NOT auto-generate for Solana here.
                        // The user must tap Next (at the bottom) to proceed. This prevents
                        // accidental generation and gives the user a chance to change
                        // selection before progressing.
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedOptionKey == key ? MetartPayColors.primaryDark : Colors.grey.shade300,
                            width: _selectedOptionKey == key ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              t['asset']!,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.monetization_on, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t['label']!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((t['standard'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      t['standard']!,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : () async {
                          // If nothing selected, prompt user
                          if (_selectedOptionKey == null) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a token/network first')));
                            return;
                          }
                          // Ensure merchant data loaded when moving to amount step
                          final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
                          if (merchantProvider.currentMerchant == null && !merchantProvider.hasAttemptedLoad) {
                            await merchantProvider.loadUserMerchants();
                          }

                          // If selected network is Solana, generate immediate address-only QR
                          final parts = _selectedOptionKey!.split('_');
                          final selNet = parts.length == 1 ? parts[0] : parts[1];
                          if (selNet.toUpperCase().startsWith('SOL')) {
                            await _generate(amountOverride: 0.0);
                            return;
                          }

                          // Otherwise, advance to amount input
                          setState(() => _step = 2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ] else if (_step == 2) ...[
                // Amount input for non-Solana networks
                // Top-left NGN badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: MetartPayColors.primaryBorder60),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/icons/naira-flag.png', height: 18),
                        const SizedBox(width: 6),
                        const Text('NGN', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Centered large amount input
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: TextFormField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        final cleaned = v.replaceAll(',', '').trim();
                        final val = double.tryParse(cleaned);
                        if (val == null || val <= 0) return 'Enter a valid numeric amount';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : () async {
                          // Ensure merchant is loaded before attempting to create a payment
                          final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
                          if (merchantProvider.currentMerchant == null && !merchantProvider.hasAttemptedLoad) {
                            await merchantProvider.loadUserMerchants();
                          }
                          if (!_formKey.currentState!.validate()) return;
                          await _generate();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
