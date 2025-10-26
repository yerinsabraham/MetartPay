class Environment {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static String get apiBaseUrl {
    switch (environment) {
      case 'staging':
        return 'https://metartpay-api-staging-xpqfkkf3oa-uc.a.run.app';
      case 'production':
        return 'https://metartpay-api-production.run.app'; // Update later
      default:
        return 'http://localhost:8080';
    }
  }

  static String get devSimulateKey {
    return const String.fromEnvironment(
      'DEV_SIMULATE_KEY',
      defaultValue: (String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') == 'staging') ? 'staging-test-key-12345' : 'dev-local-key',
    );
  }

  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';

  static bool get enableSimulate => !isProduction;
}
