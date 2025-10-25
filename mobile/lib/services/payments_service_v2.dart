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
      if (merchant == null || (merchant.walletAddresses.isEmpty ?? true)) {
        AppLogger.d(
          'DEBUG: ensureWallets - generating wallets for $merchantId',
        );
        final generated = await _firebase.generateAndSaveMerchantWallets(
          merchantId,
        );
        AppLogger.d(
          'DEBUG: ensureWallets - generated: ${generated.keys.toList()}',
        );
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
        final computed = await priceService.convertNairaToCrypto(
          amountNgn,
          token,
        );
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

        receiveAddress ??=
            fallback[network] ?? '0x0000000000000000000000000000000000000000';

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
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 15))
              .toIso8601String(),
        };
      }

      // Call backend endpoint to create a payment server-side
      final backendBase =
          AppConfig.backendBaseUrl ??
          'https://metartpay-api-456120304945.us-central1.run.app';
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
      AppLogger.d('Backend create response: ${resp.statusCode} ${resp.body}');
      if (resp.statusCode != 201 && resp.statusCode != 200) {
        AppLogger.e(
          'Backend payment create failed: ${resp.statusCode} ${resp.body}',
        );
        // Include response body to help surface validation errors (400s) to the UI
        throw Exception(
          'Failed to create payment: ${resp.statusCode} ${resp.body}',
        );
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (!(data['success'] == true)) {
        throw Exception(
          'Backend error creating payment: ${data['error'] ?? data}',
        );
      }

      // Prefer server-provided structured qr payloads. Response shape now may
      // include: qrPayloads: { addressOnly, tokenPrefill }, and cluster.
      final result = Map<String, dynamic>.from(data);
      result.remove('success');

      // If server provided structured qrPayloads, prefer the safe address-only
      // payload for Solana payments. We intentionally choose addressOnly first
      // to avoid token-prefill compatibility issues (Phantom variations, token
      // lists, etc.). Fallback to tokenPrefill only when addressOnly is absent.
      if (result['qrPayloads'] != null &&
          result['qrPayloads'] is Map<String, dynamic>) {
        final qrMap = Map<String, dynamic>.from(result['qrPayloads']);

        // Prefer addressOnly always when present (safe, simple payload)
        if (qrMap['addressOnly'] != null) {
          result['qrPayload'] = qrMap['addressOnly'];
          return result;
        }

        // If addressOnly is not available, fall back to tokenPrefill (rare)
        if (qrMap['tokenPrefill'] != null) {
          result['qrPayload'] = qrMap['tokenPrefill'];
          return result;
        }

        // If structured payloads are empty/invalid, continue to other fallbacks below
      }

      // If server didn't provide structured qrPayloads, fall back to old behavior
      if (result['qrPayload'] != null && result['qrPayload'] is String) {
        return result;
      }

      // If the server didn't provide a wallet-native qrPayload, fall back to
      // building one client-side, but avoid embedding invalid references.
      if (result['reference'] != null && result['reference'] is String) {
        final ref = result['reference'] as String;
        final base58Reg = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
        if (!base58Reg.hasMatch(ref) || ref.length < 32 || ref.length > 50) {
          // drop invalid reference
          result.remove('reference');
        }
      }

      return result;
    } catch (e, st) {
      AppLogger.e(
        'Failed to create payment via backend: $e',
        error: e,
        stackTrace: st,
      );
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
    // When true (or when global AppConfig.SOLANA_ADDRESS_ONLY_QR is true),
    // build an address-only Solana QR (solana:<address>) instead of
    // including amount/spl-token etc. Useful as a temporary fallback.
    bool forceAddressOnlyForSolana = true,
  }) {
    // Normalize inputs
    final t = token.toUpperCase();
    final net = network.toUpperCase();

    // Helper to format amounts
    String amt(double v) => v.toString();

    // Known token contract/mint mappings (DevNet / placeholders). Add real addresses as needed.
    const solanaMints = {
      'USDC': 'Es9vMFrzaCERa...replace_with_real_devnet_mint',
      'USDT': 'BQ...replace_usdt_devnet',
    };

    const ethereumContracts = {
      'USDT':
          '0x0000000000000000000000000000000000000000', // replace with real contract if available
      'USDC': '0x0000000000000000000000000000000000000000',
    };

    // SOL / Solana (supports native SOL and SPL tokens)
    if (net.startsWith('SOL')) {
      // If configured to force address-only, return the simple payload
      // (explicit solana:<address>) so wallets open a manual-send flow.
      try {
        final forceGlobal = AppConfig.SOLANA_ADDRESS_ONLY_QR;
        if (forceAddressOnlyForSolana || forceGlobal) {
          return 'solana:$address';
        }
      } catch (_) {
        // If any issue reading AppConfig, fall back to safe simple payload
        return 'solana:$address';
      }
      if (t == 'SOL' || t == 'SOLANA') {
        return 'solana:$address?amount=${amt(cryptoAmount)}';
      }
      // Do NOT generate SPL token-prefill URIs on the client. The server is
      // authoritative for token-prefill payloads and will return them under
      // qrPayloads.tokenPrefill when allowed. Always prefer address-only
      // payloads client-side to maximize compatibility with wallets.
      return 'solana:$address';
    }

    // Ethereum / EVM networks (ETH, BSC treated similarly for native coin)
    if (net == 'ETH' ||
        net == 'ETHEREUM' ||
        net == 'BSC' ||
        net == 'BSC_MAINNET') {
      if (t == 'ETH' || net == 'ETH' || net == 'ETHEREUM') {
        // value in wei
        final wei = (cryptoAmount * 1e18).round();
        return 'ethereum:$address?value=${wei.toString()}';
      }
      // ERC20 token - include contract if known
      final contract = ethereumContracts[t] ?? '';
      if (contract.isNotEmpty) {
        return 'ethereum:$address?token=${Uri.encodeComponent(contract)}&amount=${amt(cryptoAmount)}';
      }
    }

    // Bitcoin
    if (net == 'BTC' || net == 'BITCOIN') {
      return 'bitcoin:$address?amount=${amt(cryptoAmount)}';
    }

    // Tron (TRX native, TRC20 tokens)
    if (net.startsWith('TR') || net.startsWith('TRC') || net == 'TRX') {
      // native TRX
      if (t == 'TRX') {
        return 'tron:$address?amount=${amt(cryptoAmount)}';
      }
      // TRC20 token - no standard widely-adopted format; include contract param if known
      // For now include token name as token param and fall back to address only
      return 'tron:$address?token=${Uri.encodeComponent(t)}&amount=${amt(cryptoAmount)}';
    }

    // Default: legacy app-specific payload
    final encodedAddress = Uri.encodeComponent(address);
    final encodedMerchant = Uri.encodeComponent(merchantId);
    return 'metartpay://pay?amount=${cryptoAmount.toString()}&token=$token&network=$network&address=$encodedAddress&merchant=$encodedMerchant&paymentId=$paymentId';
  }

  /// Lightweight check to see if a string looks like a base58-encoded Solana pubkey.
  /// This is intentionally permissive (no decode) but prevents obvious bad strings.
  static bool looksLikeBase58Pubkey(String? s) {
    if (s == null) return false;
    final base58Reg = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    if (!base58Reg.hasMatch(s)) return false;
    if (s.length < 32 || s.length > 50) return false;
    return true;
  }
}
