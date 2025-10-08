import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBGZ08CWOcFJ0YM7BrXPkGZ18y-KsXjEdA',
    appId: '1:456120304945:android:d25797e1608277d8a15c10',
    messagingSenderId: '456120304945',
    projectId: 'metartpay-bac2f',
    storageBucket: 'metartpay-bac2f.firebasestorage.app',
  );
}