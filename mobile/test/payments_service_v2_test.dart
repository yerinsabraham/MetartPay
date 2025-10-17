import 'package:flutter_test/flutter_test.dart';
import 'package:metartpay_mobile/services/payments_service_v2.dart';

void main() {
  test('Solana address-only payload is produced when forced', () {
    final payload = PaymentsServiceV2.buildQrPayload(
      paymentId: 'p1',
      cryptoAmount: 0.05,
      token: 'SOL',
      network: 'SOL',
      address: 'DevSolTestWallet11111111111111111111111111111',
      merchantId: 'm1',
      forceAddressOnlyForSolana: true,
    );

    expect(payload, startsWith('solana:'));
    expect(payload.contains('?'), isFalse, reason: 'Address-only Solana payload must not contain query params');
    expect(payload, contains('DevSolTestWallet11111111111111111111111111111'));
  });
}
