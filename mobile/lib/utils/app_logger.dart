import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple application logger wrapper that routes logs through
/// dart:developer and gates debug output to debug mode.
class AppLogger {
  AppLogger._();

  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      // Print to stdout so 'flutter run' and terminals always show debug messages.
      // Also send to dart:developer for IDE integration.
      debugPrint('[DEBUG] $message');
      developer.log(message, name: 'metartpay.debug', error: error, stackTrace: stackTrace);
    }
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    // Info-level should be visible in consoles as well.
    debugPrint('[INFO] $message');
    developer.log(message, name: 'metartpay.info', error: error, stackTrace: stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[WARN] $message');
    developer.log(message, name: 'metartpay.warn', level: 900, error: error, stackTrace: stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');
    developer.log(message, name: 'metartpay.error', level: 1000, error: error, stackTrace: stackTrace);
  }
}
