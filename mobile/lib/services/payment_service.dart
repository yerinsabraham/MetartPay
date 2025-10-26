import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_config.dart';
import '../models/transaction_model.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class PaymentService {
  final String baseUrl;
  final Duration timeout;

  PaymentService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  // Derive a set of base roots to try for requests. This helps when the
  // supplied baseUrl points at a functions wrapper (e.g.
  // /<project>/us-central1/api) while the local server is running at the
  // host root (e.g. http://127.0.0.1:5001). We return candidates ordered
  // from most-specific to most-general.
  List<String> _deriveBaseRoots() {
    final trimmed = baseUrl.replaceAll(RegExp(r'/$'), '');
    final roots = <String>[];
    void add(String s) {
      if (s.isEmpty) return;
      if (!roots.contains(s)) roots.add(s);
    }

    add(trimmed);
    try {
      final u = Uri.parse(trimmed);
      final path = u.path;
      // If the path contains '/api', add variant before '/api'
      if (path.contains('/api')) {
        final beforeApi = trimmed
            .split('/api')
            .first
            .replaceAll(RegExp(r'/$'), '');
        add(beforeApi);
      }
      // If contains cloud function region marker like '/us-central1', add
      // variant before it (removes function wrapper portion)
      if (path.contains('/us-central1') || path.contains('/europe-west1')) {
        final idx = path.indexOf('/us-central1');
        final idx2 = path.indexOf('/europe-west1');
        final cut = (idx >= 0) ? idx : (idx2 >= 0 ? idx2 : -1);
        if (cut >= 0) {
          final before =
              '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}${path.substring(0, cut)}'
                  .replaceAll(RegExp(r'/$'), '');
          add(before);
        }
      }
      // Always add host-only root like http(s)://host:port
      final hostOnly =
          '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
      add(hostOnly);
    } catch (_) {
      // ignore parse errors and fall back to the raw trimmed value
    }
    return roots;
  }

  // Create a synthetic payment (dev mode)
  Future<String> createPayment(
    Map<String, dynamic> payload, {
    String? simulateKey,
  }) async {
    final bodyMap = payload;
    final headers = {'Content-Type': 'application/json'};
    if (simulateKey != null) headers['x-dev-simulate-key'] = simulateKey;

    final bases = _deriveBaseRoots();
    final candidates = <Uri>[];
    for (final b in bases) {
      final root = b.replaceAll(RegExp(r'/$'), '');
      // normalize: if root already ends with '/api', avoid adding another '/api'
      if (root.endsWith('/api')) {
        candidates.add(Uri.parse('$root/payments/simulate-confirm'));
      } else {
        candidates.add(Uri.parse('$root/api/payments/simulate-confirm'));
        candidates.add(Uri.parse('$root/payments/simulate-confirm'));
      }
    }

    String lastErr = '';
    for (final uri in candidates) {
      try {
        // Helpful debug logging to see which candidate we try on device.
        debugPrint('PaymentService.createPayment: trying $uri');
        final resp = await http
            .post(uri, headers: headers, body: jsonEncode(bodyMap))
            .timeout(timeout);
        debugPrint(
          'PaymentService.createPayment: response ${resp.statusCode} from $uri -> ${resp.body}',
        );
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          if (body['transactionId'] != null)
            return body['transactionId'] as String;
          throw ApiException('Missing transactionId in response');
        }
        if (resp.statusCode == 403) {
          // simulate key invalid — surface immediately
          throw ApiException('Forbidden: invalid simulate key');
        }
        // Try next candidate on 404/401
        if (resp.statusCode == 404 || resp.statusCode == 401) {
          lastErr = '${resp.statusCode} ${uri.toString()} ${resp.body}';
          continue;
        }
        throw ApiException(
          'Unexpected response: ${resp.statusCode} ${resp.body}',
        );
      } on TimeoutException catch (_) {
        lastErr = 'Request timed out for ${uri.toString()}';
        continue;
      } on http.ClientException catch (e) {
        lastErr = 'Network error for ${uri.toString()}: ${e.message}';
        continue;
      } catch (e) {
        if (e is ApiException) rethrow;
        lastErr = 'Unknown error for ${uri.toString()}: $e';
        continue;
      }
    }
    debugPrint(
      'PaymentService.createPayment: all candidates failed. lastErr=$lastErr',
    );

    // Debug-only fallback: if running in debug mode or devMockCreate enabled,
    // create a synthetic transaction + notification in Firestore so the UI
    // updates immediately for QA without requiring the backend simulate
    // endpoint. This is intentionally gated behind debug mode and AppConfig.
    if (kDebugMode || AppConfig.devMockCreate) {
      try {
        debugPrint(
          'PaymentService.createPayment: performing local debug fallback write to Firestore',
        );
        final firestore = FirebaseFirestore.instance;

        // Ensure we have an authenticated user for Firestore writes. For the
        // debug fallback, signing in anonymously is acceptable and helps avoid
        // permission-denied errors when security rules require an auth context.
        try {
          final auth = FirebaseAuth.instance;
          if (auth.currentUser == null) {
            debugPrint(
              'PaymentService.createPayment: signing in anonymously for debug fallback',
            );
            await auth.signInAnonymously();
          }
        } catch (sae) {
          debugPrint(
            'PaymentService.createPayment: anonymous sign-in failed: $sae',
          );
        }

        final tx = <String, dynamic>{
          'paymentLinkId': bodyMap['paymentLinkId'] ?? null,
          'merchantId': bodyMap['merchantId'] ?? 'dev-merchant-1',
          'txHash':
              bodyMap['txHash']?.toString() ??
              'local-${DateTime.now().millisecondsSinceEpoch}',
          'fromAddress': bodyMap['fromAddress'] ?? '',
          'toAddress': (bodyMap['toAddress'] ?? '').toString().toLowerCase(),
          'amountCrypto': (bodyMap['amountCrypto'] is num)
              ? bodyMap['amountCrypto']
              : double.tryParse((bodyMap['amountCrypto'] ?? '0').toString()) ??
                    0.0,
          'expectedAmount': null,
          'cryptoCurrency': bodyMap['cryptoCurrency'] ?? 'ETH',
          'network': bodyMap['network'] ?? 'sepolia',
          'blockNumber': bodyMap['blockNumber'] ?? 0,
          'confirmations': bodyMap['confirmations'] ?? 999,
          'requiredConfirmations': 1,
          'status': 'confirmed',
          'observedAt': FieldValue.serverTimestamp(),
          'confirmedAt': FieldValue.serverTimestamp(),
          'gasUsed': bodyMap['gasUsed'] ?? 0,
          'gasPrice': bodyMap['gasPrice'] ?? '0',
          'transactionFee': bodyMap['transactionFee'] ?? 0,
          'metadata': {...(bodyMap['metadata'] ?? {}), 'synthetic': true},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final txRef = await firestore.collection('transactions').add(tx);

        // Create notification for merchant
        try {
          final notif = {
            'merchantId': tx['merchantId'],
            'type': 'payment_received',
            'title': 'Payment Received (SIMULATED)',
            'message':
                'Received ${tx['amountCrypto']} ${tx['cryptoCurrency']} on ${tx['network']}',
            'data': {
              'transactionId': txRef.id,
              'txHash': tx['txHash'],
              'amount': tx['amountCrypto'],
              'currency': tx['cryptoCurrency'],
              'network': tx['network'],
            },
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          };
          await firestore.collection('notifications').add(notif);
        } catch (nerr) {
          debugPrint(
            'PaymentService.createPayment: failed to create local notification: $nerr',
          );
        }

        return txRef.id;
      } catch (fbErr) {
        debugPrint(
          'PaymentService.createPayment: local Firestore fallback failed: $fbErr',
        );
        // Fall through to throw original error below
      }
    }

    throw ApiException(
      lastErr.isNotEmpty ? lastErr : 'Failed to contact simulate endpoint',
    );
  }

  // Get transaction details
  Future<TransactionModel> getTransaction(String id) async {
    final bases = _deriveBaseRoots();
    // Try several base variants for the transactions GET
    final candidates = bases.map(
      (b) => Uri.parse('${b.replaceAll(RegExp(r'/$'), '')}/transactions/$id'),
    );
    Exception? lastEx;
    for (final url in candidates) {
      try {
        final resp = await http.get(url).timeout(timeout);
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          if (body['transaction'] != null) {
            return TransactionModel.fromJson(body['transaction']);
          }
          throw ApiException('Malformed response');
        } else if (resp.statusCode == 404) {
          // try next candidate
          lastEx = ApiException('Transaction not found at ${url.toString()}');
          continue;
        } else {
          lastEx = ApiException('Unexpected response: ${resp.statusCode}');
          continue;
        }
      } on TimeoutException catch (_) {
        lastEx = ApiException('Request timed out for ${url.toString()}');
        continue;
      } catch (e) {
        if (e is ApiException) rethrow;
        lastEx = ApiException('Unknown error: $e');
        continue;
      }
    }
    if (lastEx != null) throw lastEx;
    throw ApiException('Failed to contact transactions endpoint');
  }

  // Admin: re-run verification for txHash
  Future<Map<String, dynamic>> reverifyTransaction(
    String txHash, {
    String? network,
    String? tokenAddress,
  }) async {
    // Try both /api/admin and /admin prefixes to support different dev/prod
    // deployments and emulator routing.
    final body = <String, dynamic>{};
    if (network != null) body['network'] = network;
    if (tokenAddress != null) body['tokenContractAddress'] = tokenAddress;

    final bases = _deriveBaseRoots();
    final candidates = <Uri>[];
    for (final b in bases) {
      final root = b.replaceAll(RegExp(r'/$'), '');
      candidates.add(Uri.parse('$root/api/admin/reverify/$txHash'));
      candidates.add(Uri.parse('$root/admin/reverify/$txHash'));
      candidates.add(Uri.parse('$root/api/debug/dev/admin/reverify/$txHash'));
    }

    String lastErr = '';
    for (final uri in candidates) {
      try {
        final resp = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(timeout);
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        // If 404 (route not found) or 401 (unauthorized) try the next candidate
        // so dev-debug fallbacks can be attempted. Record message for final error.
        if (resp.statusCode == 404 || resp.statusCode == 401) {
          final text = resp.body;
          lastErr = '${resp.statusCode} ${uri.toString()} ${text}';
          // try next candidate
          continue;
        }
        throw ApiException(
          'Unexpected response: ${resp.statusCode} ${resp.body}',
        );
      } on TimeoutException catch (_) {
        lastErr = 'Request timed out for ${uri.toString()}';
        continue;
      } catch (e) {
        if (e is ApiException) rethrow;
        lastErr = 'Unknown error for ${uri.toString()}: $e';
        continue;
      }
    }
    throw ApiException(
      lastErr.isNotEmpty
          ? lastErr
          : 'Failed to contact admin reverify endpoint',
    );
  }
}
