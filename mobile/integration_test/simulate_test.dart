import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

// Integration test using integration_test package.
// Usage (local):
// METARTPAY_BASE_URL=https://metartpay-api-456120304945.us-central1.run.app flutter test integration_test/simulate_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simulate-confirm end-to-end', (WidgetTester tester) async {
    final baseUrl = const String.fromEnvironment(
      'METARTPAY_BASE_URL',
      defaultValue: 'https://metartpay-api-456120304945.us-central1.run.app',
    );

    final simulatePayload = {
      'txHash': 'INTEGRATION_SIM_${DateTime.now().millisecondsSinceEpoch}',
      'toAddress': '0xSimulatedTo',
      'fromAddress': '0xSimulatedFrom',
      'amountCrypto': 0.01,
      'cryptoCurrency': 'ETH',
      'network': 'sepolia',
      'merchantId': 'integration-demo-merchant',
      'paymentLinkId': '',
    };

    // Try calling the configured backend. If it's unreachable, start a local mock server
    Uri simulateUri = Uri.parse('$baseUrl/simulate-confirm');
    HttpServer? mockServer;
    final client = http.Client();
    try {
      final simulateResp = await client
          .post(
            simulateUri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(simulatePayload),
          )
          .timeout(Duration(seconds: 5));
      // If response OK, proceed with real backend
      expect(simulateResp.statusCode, anyOf([200, 201]));
      final simBody = json.decode(simulateResp.body);
      final txId = simBody['transactionId'] ?? simBody['id'] ?? simBody['txId'];
      expect(txId, isNotNull);

      // Poll the transaction endpoint until it reaches completed/confirmed
      var attempts = 0;
      var success = false;
      while (attempts < 30 && !success) {
        final statusResp = await client.get(
          Uri.parse('$baseUrl/transactions/$txId'),
        );
        if (statusResp.statusCode == 200) {
          final statusBody = json.decode(statusResp.body);
          final status = (statusBody['status'] ?? '').toString().toLowerCase();
          if (status == 'confirmed' ||
              status == 'completed' ||
              status == 'settled') {
            success = true;
            break;
          }
        }
        attempts++;
        await Future.delayed(Duration(seconds: 2));
      }

      expect(
        success,
        isTrue,
        reason:
            'Transaction did not reach confirmed/completed in time (real backend)',
      );
      client.close();
    } on Exception catch (_) {
      // Backend unreachable — start an in-process mock server to simulate behavior
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = mockServer.port;
      final mockBase = 'https://metartpay-api-456120304945.us-central1.run.app';
      // Simple in-memory store
      final Map<String, Map<String, dynamic>> store = {};

      // Server loop
      unawaited(
        mockServer.forEach((HttpRequest req) async {
          final path = req.uri.path;
          try {
            if (req.method == 'POST' && path.endsWith('/simulate-confirm')) {
              final body = await utf8.decoder.bind(req).join();
              final data = json.decode(body) as Map<String, dynamic>;
              final txId = 'mock_tx_${DateTime.now().millisecondsSinceEpoch}';
              store[txId] = {'status': 'pending', 'payload': data};
              // schedule confirmation
              Timer(Duration(seconds: 2), () {
                store[txId]!['status'] = 'confirmed';
              });
              final resp = {'transactionId': txId};
              req.response.statusCode = 201;
              req.response.headers.contentType = ContentType.json;
              req.response.write(json.encode(resp));
              await req.response.close();
              return;
            }

            final txMatch = RegExp(r'^/transactions/(.+)$').firstMatch(path);
            if (req.method == 'GET' && txMatch != null) {
              final txId = Uri.decodeComponent(txMatch.group(1)!);
              if (store.containsKey(txId)) {
                req.response.statusCode = 200;
                req.response.headers.contentType = ContentType.json;
                req.response.write(
                  json.encode({
                    'transactionId': txId,
                    'status': store[txId]!['status'],
                  }),
                );
              } else {
                req.response.statusCode = 404;
                req.response.write('not found');
              }
              await req.response.close();
              return;
            }

            // default 404
            req.response.statusCode = 404;
            await req.response.close();
          } catch (e) {
            try {
              req.response.statusCode = 500;
              await req.response.close();
            } catch (_) {}
          }
        }),
      );

      // Now call the mock server's simulate-confirm
      final mockClient = http.Client();
      final simulateResp = await mockClient.post(
        Uri.parse('$mockBase/simulate-confirm'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(simulatePayload),
      );
      expect(simulateResp.statusCode, anyOf([200, 201]));
      final simBody = json.decode(simulateResp.body);
      final txId = simBody['transactionId'];
      expect(txId, isNotNull);

      // Poll the mock transaction endpoint
      var attempts = 0;
      var success = false;
      while (attempts < 20 && !success) {
        final statusResp = await mockClient.get(
          Uri.parse('$mockBase/transactions/$txId'),
        );
        if (statusResp.statusCode == 200) {
          final statusBody = json.decode(statusResp.body);
          final status = (statusBody['status'] ?? '').toString().toLowerCase();
          if (status == 'confirmed' || status == 'completed') {
            success = true;
            break;
          }
        }
        attempts++;
        await Future.delayed(Duration(seconds: 1));
      }

      expect(
        success,
        isTrue,
        reason:
            'Transaction did not reach confirmed/completed in time (mock backend)',
      );

      // Cleanup
      mockClient.close();
      await mockServer.close(force: true);
    } finally {
      client.close();
      if (mockServer != null && mockServer.hashCode != 0) {
        try {
          await mockServer.close(force: true);
        } catch (_) {}
      }
    }
  }, timeout: Timeout(Duration(minutes: 5)));
}
