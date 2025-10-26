import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// Integration test scaffold: hit the backend simulate endpoint and poll for status.
// This is a scaffold; running it requires a Flutter integration test runner and an
// emulator or local backend reachable at METARTPAY_BASE_URL.

void main() {
  test('simulate flow scaffold', () async {
    final baseUrl = const String.fromEnvironment('METARTPAY_BASE_URL', defaultValue: 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api');

    final simulatePayload = {
      'txHash': 'INTEGRATION_SIM_${DateTime.now().millisecondsSinceEpoch}',
      'toAddress': '0xSimulatedTo',
      'fromAddress': '0xSimulatedFrom',
      'amountCrypto': 0.01,
      'cryptoCurrency': 'ETH',
      'network': 'sepolia',
      'merchantId': 'integration-demo-merchant',
      'paymentLinkId': ''
    };

    final resp = await http.post(Uri.parse('$baseUrl/simulate'), headers: {'Content-Type': 'application/json'}, body: json.encode(simulatePayload));
    expect(resp.statusCode, anyOf([200,201]));

    final body = json.decode(resp.body);
    expect(body['transactionId'], isNotNull);

    final txId = body['transactionId'];

    // Poll status
    var attempts = 0;
    var success = false;
    while (attempts < 20 && !success) {
      final statusResp = await http.get(Uri.parse('$baseUrl/transactions/$txId'));
      if (statusResp.statusCode == 200) {
        final statusBody = json.decode(statusResp.body);
        final status = statusBody['status'] ?? '';
        if (status == 'confirmed' || status == 'completed') {
          success = true;
          break;
        }
      }
      attempts++;
      await Future.delayed(Duration(seconds: 2));
    }

    expect(success, isTrue, reason: 'Transaction did not reach confirmed/completed in time');
  }, timeout: Timeout(Duration(minutes: 3)));
}
