import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
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

    // In debug builds we can optionally connect to the local Firebase emulators.
    // Enable by passing --dart-define=USE_FIREBASE_EMULATOR=true when running.
    const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
    if (!bool.fromEnvironment('dart.vm.product') && useEmulator) {
      try {
    // On a physical device we expect adb reverse to be used so 127.0.0.1 maps to host.
    final firestoreHost = const String.fromEnvironment('EMULATOR_FIRESTORE_HOST', defaultValue: '127.0.0.1');

    AppLogger.d('DEBUG: Configuring Firestore emulator at $firestoreHost:8080');
    FirebaseFirestore.instance.useFirestoreEmulator(firestoreHost, 8080);
      } catch (e, s) {
        AppLogger.e('DEBUG: Failed to configure Firebase emulators: $e', error: e, stackTrace: s);
      }
    }

    // Initialize Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.d('DEBUG: Firebase Messaging background handler registered');

  } catch (e, s) {
    AppLogger.e('DEBUG: Firebase initialization failed: $e', error: e, stackTrace: s);
    // Continue app launch even if Firebase fails
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
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating AuthProvider');
          return AuthProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating MerchantProvider');
          return MerchantProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating WalletProvider');
          return WalletProvider();
        }),
        ChangeNotifierProxyProvider<MerchantProvider, PaymentLinkProvider>(
          create: (context) {
            AppLogger.d('DEBUG: Creating PaymentLinkProvider');
            return PaymentLinkProvider(context.read<MerchantProvider>());
          },
          update: (context, merchantProvider, previous) {
            return previous ?? PaymentLinkProvider(merchantProvider);
          },
        ),
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating NotificationProvider');
          return NotificationProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating SecurityProvider');
          return SecurityProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.d('DEBUG: Creating CustomerProvider');
          return CustomerProvider();
        }),
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
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
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
  // Use AuthWrapper as the app's entry so unauthenticated users see login first.
  home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomePageNew(),
          '/home-v2': (context) => const HomePageNew(),
          // Lightweight alias routes for HomeController navigation
          '/receive': (context) {
            final merchantId = Provider.of<MerchantProvider>(context, listen: false).currentMerchant?.id ?? '';
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
          if (!bool.fromEnvironment('dart.vm.product')) '/demo-simulate': (context) {
            final baseUrl = const String.fromEnvironment('METARTPAY_BASE_URL', defaultValue: 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api');
            return DemoSimulatePage(baseUrl: baseUrl);
          },
        },
      ),
    );
  }
}
