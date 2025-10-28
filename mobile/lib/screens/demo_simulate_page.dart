import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/dev_simulate_toggle.dart';
import '../services/payment_service.dart';
import 'payment_status_screen.dart';

class DemoSimulatePage extends StatefulWidget {
  final String baseUrl;
  const DemoSimulatePage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  _DemoSimulatePageState createState() => _DemoSimulatePageState();
}

class _DemoSimulatePageState extends State<DemoSimulatePage> {
  late PaymentService _svc;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Adjust baseUrl for Android emulators where localhost refers to the device
    var effectiveBase = widget.baseUrl;
    if ((effectiveBase.contains('127.0.0.1') || effectiveBase.contains('localhost')) && Platform.isAndroid) {
      // Android emulator maps host localhost to 10.0.2.2
      effectiveBase = effectiveBase.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }
    _svc = PaymentService(baseUrl: effectiveBase);
  }

  Future<void> _simulateAndOpen() async {
    setState(() => _busy = true);
    try {
      final payload = {
        'txHash': 'SIM_TEST_${DateTime.now().millisecondsSinceEpoch}',
        'toAddress': 'simulated-address-1',
        'fromAddress': 'simulated-sender',
        'amountCrypto': 0.25,
        'cryptoCurrency': 'ETH',
        'network': 'sepolia',
        'merchantId': 'dev-merchant-1',
        'paymentLinkId': ''
      };
  final simulateKey = const String.fromEnvironment('DEV_SIMULATE_KEY', defaultValue: 'dev-local-key');
  final txId = await _svc.createPayment(payload, simulateKey: simulateKey);
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentStatusScreen(transactionId: txId, baseUrl: widget.baseUrl)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulate failed: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo: Simulate Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dev simulate flow (debug only)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DevSimulateToggle(baseUrl: widget.baseUrl),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: _busy ? const Text('Simulating...') : const Text('Simulate & Open Status'),
              onPressed: kDebugMode && !_busy ? _simulateAndOpen : null,
            ),
            const SizedBox(height: 12),
            const Text('Note: This demo expects backend emulator or backend dev server reachable at the base URL.'),
          ],
        ),
      ),
    );
  }
}
