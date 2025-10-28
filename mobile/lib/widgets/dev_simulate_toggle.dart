import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class DevSimulateToggle extends StatefulWidget {
  final String baseUrl;
  const DevSimulateToggle({Key? key, required this.baseUrl}) : super(key: key);

  @override
  _DevSimulateToggleState createState() => _DevSimulateToggleState();
}

class _DevSimulateToggleState extends State<DevSimulateToggle> {
  bool _enabled = false;
  bool _busy = false;
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
  _paymentService = PaymentService(baseUrl: widget.baseUrl);
  }

  Future<void> _simulate() async {
    setState(() => _busy = true);
    try {
      final payload = {
        'txHash': 'SIM_TEST_${DateTime.now().millisecondsSinceEpoch}',
        'toAddress': 'simulated-address-1',
        'fromAddress': 'simulated-sender',
        'amountCrypto': 0.1,
        'cryptoCurrency': 'ETH',
        'network': 'sepolia',
        'merchantId': 'dev-merchant-1',
        'paymentLinkId': ''
      };
  final txId = await _paymentService.createPayment(payload, simulateKey: 'dev-local-key');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated tx: $txId')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulate failed: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Dev simulate'),
            Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
            ElevatedButton(onPressed: _enabled && !_busy ? _simulate : null, child: _busy ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Simulate'))
          ],
        )
      ],
    );
  }
}
