import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/dev_simulate_toggle.dart';
import '../services/payment_service.dart';
import 'payment_status_screen.dart';
import '../utils/app_config.dart';

class DemoSimulatePage extends StatefulWidget {
  final String baseUrl;
  const DemoSimulatePage({super.key, required this.baseUrl});

  @override
  _DemoSimulatePageState createState() => _DemoSimulatePageState();
}

class _DemoSimulatePageState extends State<DemoSimulatePage> {
  late final PaymentService _svc;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _svc = PaymentService(baseUrl: widget.baseUrl);
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
        'paymentLinkId': '',
      };
      final txId = await _svc.createPayment(
        payload,
        simulateKey: AppConfig.devSimulateKey,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PaymentStatusScreen(transactionId: txId, baseUrl: widget.baseUrl),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Simulate failed: $e')));
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
            const Text(
              'Dev simulate flow (debug only)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DevSimulateToggle(baseUrl: widget.baseUrl),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: _busy
                  ? const Text('Simulating...')
                  : const Text('Simulate & Open Status'),
              onPressed: kDebugMode && !_busy ? _simulateAndOpen : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Note: This demo expects backend emulator or backend dev server reachable at the base URL.',
            ),
          ],
        ),
      ),
    );
  }
}
