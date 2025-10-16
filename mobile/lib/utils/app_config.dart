class AppConfig {
  // The backend base URL for API calls. In production this should be set
  // from build-time environment variables or a config file.
  // Default to the staging backend so local debug runs hit staging when no build
  // environment variable is provided. Change back before production builds.
  static const String? backendBaseUrl = String.fromEnvironment(
    'METARTPAY_BACKEND_BASE_URL',
    defaultValue: 'https://api-xpqfkkf3oa-uc.a.run.app',
  );

  // When true the mobile app will synthesize a server-shaped payment
  // response locally (no Firestore write). Must be false in production.
  static const bool devMockCreate = bool.fromEnvironment('METARTPAY_DEV_MOCK_CREATE', defaultValue: false);
}
