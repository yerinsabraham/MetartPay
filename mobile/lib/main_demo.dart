import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/demo_simulate_page.dart';

// Minimal demo entrypoint. To run: `flutter run -t lib/main_demo.dart` after
// you've configured Firebase or have the backend emulator running.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseUrl = const String.fromEnvironment('METARTPAY_BASE_URL', defaultValue: 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api');

    return MaterialApp(
      title: 'MetartPay Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DemoSimulatePage(baseUrl: baseUrl),
    );
  }
}
