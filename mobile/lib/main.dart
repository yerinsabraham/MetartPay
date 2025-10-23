import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/home/home_page_new.dart';
import 'screens/receive_payments_screen.dart';
import 'screens/payment_links/create_payment_link_screen.dart';
import 'screens/payment_links/payment_links_screen.dart';
import 'screens/wallets/crypto_wallets_screen.dart';
import 'screens/payments/create_payment_v2.dart';
import 'screens/payments/qr_view_v2.dart';
import 'screens/transactions/transaction_history_screen.dart';
import 'screens/setup/merchant_setup_wizard.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/demo_simulate_page.dart';
import 'providers/auth_provider.dart';
import 'providers/merchant_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/payment_link_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/security_provider.dart';
import 'providers/customer_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.d('DEBUG: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.d('DEBUG: Firebase initialized successfully');
    AppLogger.d('DEBUG: Project ID: ${Firebase.app().options.projectId}');

    // Initialize Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.d('DEBUG: Firebase Messaging background handler registered');
  } catch (e, s) {
    AppLogger.e(
      'DEBUG: Firebase initialization failed: $e',
      error: e,
      stackTrace: s,
    );
    // Continue app launch even if Firebase fails
  }

  // In debug builds, prefer connecting to the local Firestore emulator so
  // we don't hit production rules. This is best-effort and will try both
  // the convenience API and a Settings fallback for older plugin versions.
  final baseUrl = const String.fromEnvironment(
    'METARTPAY_BASE_URL',
    defaultValue: 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api',
  );
  final shouldUseEmulator =
      !bool.fromEnvironment('dart.vm.product') ||
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('10.0.2.2') ||
      const bool.fromEnvironment(
        'FORCE_FIRESTORE_EMULATOR',
        defaultValue: false,
      );
  if (shouldUseEmulator) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      AppLogger.d(
        'DEBUG: Firestore emulator configured via useFirestoreEmulator',
      );
      // Also explicitly set Settings host to 127.0.0.1:8080 on debug devices.
      // Some plugin/platform combos remap to 10.0.2.2 internally which
      // doesn't work for physical devices; enforcing Settings ensures
      // the client targets localhost which `adb reverse` forwards.
      try {
        FirebaseFirestore.instance.settings = Settings(
          host: '127.0.0.1:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );
        AppLogger.d(
          'DEBUG: Firestore settings host explicitly set to 127.0.0.1:8080',
        );
      } catch (es) {
        AppLogger.w(
          'DEBUG: Failed to explicitly set Firestore settings after useFirestoreEmulator: $es',
        );
      }
    } catch (e) {
      try {
        FirebaseFirestore.instance.settings = Settings(
          host: '127.0.0.1:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );
        AppLogger.d(
          'DEBUG: Firestore emulator configured via Settings fallback',
        );
      } catch (e2) {
        AppLogger.e('DEBUG: Failed to configure Firestore emulator: $e / $e2');
      }
    }
  }

  AppLogger.d('DEBUG: Launching MetartPay...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.d('DEBUG: Building MetartPay App');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating AuthProvider');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating MerchantProvider');
            return MerchantProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating WalletProvider');
            return WalletProvider();
          },
        ),
        ChangeNotifierProxyProvider<MerchantProvider, PaymentLinkProvider>(
          create: (context) {
            AppLogger.d('DEBUG: Creating PaymentLinkProvider');
            return PaymentLinkProvider(context.read<MerchantProvider>());
          },
          update: (context, merchantProvider, previous) {
            return previous ?? PaymentLinkProvider(merchantProvider);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating NotificationProvider');
            return NotificationProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating SecurityProvider');
            return SecurityProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            AppLogger.d('DEBUG: Creating CustomerProvider');
            return CustomerProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'MetartPay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC62B14), // Updated app theme color
            brightness: Brightness.light,
            primary: const Color(0xFFC62B14),
            secondary: const Color(0xFFf79816),
            tertiary: const Color(0xFFe05414),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC62B14), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC62B14), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC62B14), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade700, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade700, width: 2),
            ),
            floatingLabelStyle: TextStyle(color: Color(0xFFC62B14)),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Set Home V2 (new simplified home) as the initial page per request.
        // In debug builds use HomePageNewWrapper which adds a Demo FAB.
        home: !bool.fromEnvironment('dart.vm.product')
            ? const HomePageNewWrapper()
            : const HomePageNew(),
        routes: {
          '/home': (context) => const HomePageNew(),
          '/home-v2': (context) => const HomePageNew(),
          // Lightweight alias routes for HomeController navigation
          '/receive': (context) {
            final merchantId =
                Provider.of<MerchantProvider>(
                  context,
                  listen: false,
                ).currentMerchant?.id ??
                '';
            return ReceivePaymentsScreen(merchantId: merchantId);
          },
          '/create-payment-link': (context) => const CreatePaymentLinkScreen(),
          '/create-payment-v2': (context) => const CreatePaymentV2(),
          '/qr-view-v2': (context) => QRViewV2(),
          '/payment-links': (context) => const PaymentLinksScreen(),
          '/wallets': (context) => const CryptoWalletsScreen(),
          '/transactions': (context) => const TransactionHistoryScreen(),
          '/setup': (context) => const MerchantSetupWizard(),
          '/profile': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          // Debug/demo route - only enabled in debug builds
          if (!bool.fromEnvironment('dart.vm.product'))
            '/demo-simulate': (context) {
              final baseUrl = const String.fromEnvironment(
                'METARTPAY_BASE_URL',
                defaultValue:
                    'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api',
              );
              return DemoSimulatePage(baseUrl: baseUrl);
            },
        },
      ),
    );
  }
}
