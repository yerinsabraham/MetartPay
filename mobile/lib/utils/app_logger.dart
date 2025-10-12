import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple application logger wrapper that routes logs through
/// dart:developer and gates debug output to debug mode.
class AppLogger {
  AppLogger._();

  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(message, name: 'metartpay.debug', error: error, stackTrace: stackTrace);
    }
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'metartpay.info', error: error, stackTrace: stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'metartpay.warn', level: 900, error: error, stackTrace: stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'metartpay.error', level: 1000, error: error, stackTrace: stackTrace);
  }
}
