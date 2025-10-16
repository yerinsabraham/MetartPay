import 'package:flutter/material.dart';

void main() {
  debugPrint('🚀 DEBUG: Starting simple test app (no Firebase)');
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetartPay Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MetartPay - Connection Test'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text(
                'App Launch Successful! ✅',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'MetartPay is working properly',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('1. App launches successfully'),
                      Text('2. No package name conflicts'),
                      Text('3. Ready to add Firebase back'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}