import '../services/crypto_price_service.dart';
import '../services/payments_service_v2.dart';
import '../utils/app_logger.dart';

class PaymentControllerV2 {
  final PaymentsServiceV2 _service = PaymentsServiceV2();
  final CryptoPriceService _priceService = CryptoPriceService();

  Future<Map<String, dynamic>> createPayment({
    required String merchantId,
    required double amountNgn,
    required String token,
    required String network,
    String? description,
    bool autoConvert = true,
  }) async {
    // Ensure wallets exist
    final walletsOk = await _service.ensureWallets(merchantId);
    if (!walletsOk) {
      throw Exception('Merchant wallets could not be generated or are missing.');
    }

    // Fetch price
    final price = await _priceService.getCryptoPrice(token);
    final cryptoAmount = price != null && price.priceInNGN > 0 ? (amountNgn / price.priceInNGN) : 0.0;

    // Create payment record via service
    final result = await _service.createPayment(
      merchantId: merchantId,
      amountNgn: amountNgn,
      cryptoAmount: cryptoAmount,
      token: token,
      network: network,
      description: description,
      autoConvert: autoConvert,
    );

    AppLogger.d('DEBUG: PaymentControllerV2 created payment: $result');
    return result;
  }
}
