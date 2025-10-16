import 'package:flutter/material.dart';
import '../../utils/app_logger.dart';

class HomeController {
  static void openReceivePayments(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Receive Payments');
    Navigator.pushNamed(context, '/receive');
  }

  static void openCreatePaymentLink(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Create Payment Link');
    Navigator.pushNamed(context, '/create-payment-link');
  }

  static void openCreatePayment(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Create Payment (V2)');
    Navigator.pushNamed(context, '/create-payment-v2');
  }

  static void openPaymentLinks(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Payment Links');
    Navigator.pushNamed(context, '/payment-links');
  }

  static void openWallet(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Wallet');
    Navigator.pushNamed(context, '/wallets');
  }

  static void openTransactions(BuildContext context) {
    AppLogger.d('DEBUG: Navigate -> Transactions');
    Navigator.pushNamed(context, '/transactions');
  }
}
