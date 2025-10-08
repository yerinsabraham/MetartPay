// Debug Test for Firebase Authentication
// Run this in your Flutter app to test Firebase connection

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  String _status = 'Checking Firebase connection...';
  final _emailController = TextEditingController(text: 'test@metartpay.com');
  final _passwordController = TextEditingController(text: 'TestPass123');

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      // Check Firebase initialization
      await Firebase.initializeApp();
      
      // Check Firebase Auth instance
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      setState(() {
        _status = '''
✅ Firebase Core: Initialized
✅ Firebase Auth: Available
👤 Current User: ${currentUser?.email ?? 'None'}
🔗 Project ID: ${Firebase.app().options.projectId}
📱 App ID: ${Firebase.app().options.appId}

Ready for authentication testing!
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase Error: $e';
      });
    }
  }

  Future<void> _testEmailSignup() async {
    setState(() {
      _status = 'Testing email signup...';
    });
    
    try {
      final auth = FirebaseAuth.instance;
      final result = await auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      setState(() {
        _status = '''
✅ Email Signup Success!
📧 User: ${result.user?.email}
🆔 UID: ${result.user?.uid}
✉️ Email Verified: ${result.user?.emailVerified}
        ''';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = '''
❌ Email Signup Failed
Code: ${e.code}
Message: ${e.message}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Unexpected Error: $e';
      });
    }
  }

  Future<void> _testEmailLogin() async {
    setState(() {
      _status = 'Testing email login...';
    });
    
    try {
      final auth = FirebaseAuth.instance;
      final result = await auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      setState(() {
        _status = '''
✅ Email Login Success!
📧 User: ${result.user?.email}
🆔 UID: ${result.user?.uid}
⏰ Last Sign In: ${result.user?.metadata.lastSignInTime}
        ''';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = '''
❌ Email Login Failed
Code: ${e.code}
Message: ${e.message}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Unexpected Error: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _status = '✅ Signed out successfully';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Sign out error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testEmailSignup,
                    child: const Text('Test Signup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testEmailLogin,
                    child: const Text('Test Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _checkFirebaseStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}