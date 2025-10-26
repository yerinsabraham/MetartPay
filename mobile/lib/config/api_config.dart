import 'environment.dart';

class ApiConfig {
  // Use Environment to determine base URL so we can switch between dev/staging/prod
  static String get apiBaseUrl => Environment.apiBaseUrl;

  // Backwards-compatible alias used by older code that referenced ApiConfig.baseUrl
  static String get baseUrl => apiBaseUrl;

  // Request timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // API endpoints
  static const String authEndpoint = '/api/auth';
  static const String merchantsEndpoint = '/api/merchants';
  static const String walletsEndpoint = '/api/wallets';
  static const String invoicesEndpoint = '/api/invoices';
  static const String paymentsEndpoint = '/api/payments';
}
