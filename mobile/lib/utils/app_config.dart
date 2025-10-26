import 'package:flutter/foundation.dart';
import '../config/environment.dart';

class AppConfig {
  // The backend base URL for API calls. Prefer using Environment so
  // builds targeting staging/production will use the correct host.
  static String get backendBaseUrl => '${Environment.apiBaseUrl}/api';

  // Dev simulate key is now sourced from Environment (can still be overridden
  // via --dart-define=DEV_SIMULATE_KEY if desired).
  static String get devSimulateKey => Environment.devSimulateKey;

  // When true the mobile app will synthesize a server-shaped payment
  // response locally (no Firestore write). For developer convenience this
  // flag is enabled automatically when running in debug mode so you don't
  // need to pass --dart-define during local development. In release builds
  // it remains false unless the environment variable is explicitly set.
  static final bool devMockCreate =
      bool.fromEnvironment('METARTPAY_DEV_MOCK_CREATE', defaultValue: false) ||
      kDebugMode;

  // When true, generate Solana QR codes as address-only (solana:<address>)
  // instead of full Solana Pay URIs with amount/params. Toggleable via
  // --dart-define=SOLANA_ADDRESS_ONLY_QR=false when building if you want
  // to re-enable full Solana Pay URIs.
  static const bool SOLANA_ADDRESS_ONLY_QR = bool.fromEnvironment(
    'SOLANA_ADDRESS_ONLY_QR',
    defaultValue: true,
  );

  // The cluster the backend expects for generated QR payloads. This is used
  // by the mobile client to decide whether to use token-prefill QR payloads
  // returned by the server. Use build-time defines to control this.
  static const String backendCluster = String.fromEnvironment(
    'METARTPAY_BACKEND_CLUSTER',
    defaultValue: '',
  );
}
