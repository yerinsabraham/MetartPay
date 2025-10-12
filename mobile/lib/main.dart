import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/home/home_screen.dart';
import 'screens/setup/merchant_setup_wizard.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
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
            seedColor: const Color(0xFF681f28), // Official MetartPay brand color
            brightness: Brightness.light,
            primary: const Color(0xFF681f28),
            secondary: const Color(0xFFf79816),
            tertiary: const Color(0xFFe05414),
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
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/setup': (context) => const MerchantSetupWizard(),
          '/profile': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
