class ApiConfig {
  // Backend API base URL - change this to your Firebase Functions URL or custom domain
  static const String baseUrl = 'https://metartpay-api-456120304945.us-central1.run.app';
  
  // Local development URL (when running emulator)
  static const String localUrl = 'http://localhost:5001/metartpay-bac2f/us-central1/api';
  
  // Use local URL for development, production URL for release
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static String get apiBaseUrl => isProduction ? baseUrl : localUrl;
  
  // Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  // API endpoints
  static const String authEndpoint = '/api/auth';
  static const String merchantsEndpoint = '/api/merchants';
  static const String walletsEndpoint = '/api/wallets';
  static const String invoicesEndpoint = '/api/invoices';
  static const String paymentsEndpoint = '/api/payments';
}