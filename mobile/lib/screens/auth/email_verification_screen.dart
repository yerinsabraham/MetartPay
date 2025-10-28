import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendEmailVerification();

    setState(() {
      _isSending = false;
      _message = ok ? 'Verification email sent.' : 'Failed to send verification email.';
    });
  }

  Future<void> _checkVerified() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final auth = context.read<AuthProvider>();
    final verified = await auth.reloadCurrentUser();

    setState(() {
      _isChecking = false;
    });

    if (verified) {
      // AuthWrapper will respond to provider change and route user forward
      setState(() {
        _message = 'Email verified — redirecting...';
      });
    } else {
      setState(() {
        _message = 'Email still not verified. Check your inbox and click the verification link.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'A verification email has been sent to the address you used to sign up. Please open the email and click the verification link to continue.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkVerified,
              child: _isChecking
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('I have verified — Continue'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSending ? null : _resend,
              child: _isSending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Resend verification email'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                // Allow user to sign out if they want to use a different email
                await auth.signOut();
              },
              child: const Text('Use a different email / Sign out'),
            ),
            const SizedBox(height: 12),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
