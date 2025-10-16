import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../utils/app_logger.dart';
import '../utils/app_config.dart';
import '../services/crypto_price_service.dart';

class PaymentsServiceV2 {
  final FirebaseService _firebase = FirebaseService();
  // moved payment creation to backend; no direct Firestore instance required here

  /// Ensure merchant wallets exist. Returns true if wallets are present (either already
  /// present or successfully generated). Returns false if an error occurred.
  Future<bool> ensureWallets(String merchantId) async {
    try {
      final merchant = await _firebase.getMerchant(merchantId);
      if (merchant == null || (merchant.walletAddresses?.isEmpty ?? true)) {
        AppLogger.d('DEBUG: ensureWallets - generating wallets for $merchantId');
        final generated = await _firebase.generateAndSaveMerchantWallets(merchantId);
        AppLogger.d('DEBUG: ensureWallets - generated: ${generated.keys.toList()}');
        return generated.isNotEmpty;
      }
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to ensure wallets: $e', error: e, stackTrace: st);
      // Do not rethrow; return false to let caller decide how to proceed
      return false;
    }
  }

  Future<Map<String, dynamic>> createPayment({
    required String merchantId,
    required double amountNgn,
    required double cryptoAmount,
    required String token,
    required String network,
    String? description,
    bool autoConvert = true,
  }) async {
    try {
      // Dev mock path: synthesize a server-shaped response without writing to Firestore
      if (AppConfig.devMockCreate) {
        AppLogger.d('DEV: Using mock createPayment path');
        final priceService = CryptoPriceService();
        final computed = await priceService.convertNairaToCrypto(amountNgn, token);
        final double cryptoAmt = computed ?? cryptoAmount;

        // Try to get merchant wallet address (reads are typically allowed)
        String? receiveAddress;
        try {
          final merchant = await _firebase.getMerchant(merchantId);
          final wa = merchant?.walletAddresses;
          if (wa != null && wa.containsKey(network)) {
            receiveAddress = wa[network]?.toString();
          }
        } catch (e) {
          AppLogger.w('DEV: Could not read merchant wallet: $e');
        }

        // Fallback dev addresses map
        final fallback = {
          'SOL': 'DevSolTestWallet11111111111111111111111111111',
          'BSC': '0x0000000000000000000000000000000000000000',
          'ETH': '0x0000000000000000000000000000000000000000',
          'TRC20': 'TNdevFallbackAddress11111111111111111',
        };

        receiveAddress ??= fallback[network] ?? '0x0000000000000000000000000000000000000000';

        final paymentId = 'local-${DateTime.now().millisecondsSinceEpoch}';
        final qrPayload = PaymentsServiceV2.buildQrPayload(
          paymentId: paymentId,
          cryptoAmount: cryptoAmt,
          token: token,
          network: network,
          address: receiveAddress,
          merchantId: merchantId,
        );

        return {
          'success': true,
          'paymentId': paymentId,
          'qrPayload': qrPayload,
          'cryptoAmount': cryptoAmt,
          'address': receiveAddress,
          'token': token,
          'network': network,
          'expiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        };
      }

      // Call backend endpoint to create a payment server-side
      final backendBase = AppConfig.backendBaseUrl ?? 'http://localhost:3000';
      final url = Uri.parse('$backendBase/api/payments/create');

      final body = json.encode({
        'merchantId': merchantId,
        'amountNgn': amountNgn,
        'token': token,
        'network': network,
        'description': description ?? '',
      });

      AppLogger.d('Creating payment via backend: $url body: $body');

      // Attach Firebase ID token for authentication to the backend
      final idToken = await _firebase.getIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final resp = await http.post(url, headers: headers, body: body);
      if (resp.statusCode != 201 && resp.statusCode != 200) {
        AppLogger.e('Backend payment create failed: ${resp.statusCode} ${resp.body}');
        throw Exception('Failed to create payment: ${resp.statusCode}');
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (!(data['success'] == true)) {
        throw Exception('Backend error creating payment: ${data['error'] ?? data}');
      }

      // Return the payload data (spread top-level fields through)
      final result = Map<String, dynamic>.from(data);
      result.remove('success');
      return result;

    } catch (e, st) {
      AppLogger.e('Failed to create payment via backend: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Build a consistent QR payload string used by both mock and real backends.
  /// Format: metartpay://pay?amount=<cryptoAmount>&token=<token>&network=<network>&address=<address>&merchant=<merchantId>&paymentId=<paymentId>
  static String buildQrPayload({
    required String paymentId,
    required double cryptoAmount,
    required String token,
    required String network,
    required String address,
    required String merchantId,
  }) {
    final encodedAddress = Uri.encodeComponent(address);
    final encodedMerchant = Uri.encodeComponent(merchantId);
    return 'metartpay://pay?amount=${cryptoAmount.toString()}&token=$token&network=$network&address=$encodedAddress&merchant=$encodedMerchant&paymentId=$paymentId';
  }
}
