import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../providers/merchant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/metartpay_branding.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isDemoSigning = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // On successful login, ensure merchant data is loaded and navigate
      // to the home screen. Use pushNamedAndRemoveUntil so the login stack is cleared.
      if (success && mounted) {
        try {
          final merchantProvider = context.read<MerchantProvider>();
          await merchantProvider.loadUserMerchants();
        } catch (e) {
          // Non-fatal: log and continue to home
          AppLogger.w('DEBUG: Failed to load merchants after login: $e', error: e);
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
      }
    }
  }

  void _loginWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Google sign-in failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // On successful Google sign-in, load merchant data and navigate to home
    if (success && mounted) {
      try {
        final merchantProvider = context.read<MerchantProvider>();
        await merchantProvider.loadUserMerchants();
      } catch (e) {
        AppLogger.w('DEBUG: Failed to load merchants after Google sign-in: $e', error: e);
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    }
  }

  Future<void> _signInAsDemo() async {
    if (!kDebugMode) return;
    setState(() {
      _isDemoSigning = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Sign in anonymously
      final auth = fb_auth.FirebaseAuth.instance;
      final userCred = await auth.signInAnonymously();

      if (userCred.user == null) {
        throw Exception('Anonymous sign-in failed');
      }

      // Create a demo merchant for this anonymous user so the app has data
      final merchantProvider = context.read<MerchantProvider>();

      final created = await merchantProvider.createMerchantWithSetup(
        businessName: 'Demo Business',
        industry: 'Demo',
        contactEmail: 'demo@example.com',
        fullName: 'Demo User',
        bankAccountNumber: '0000000000',
        bankName: 'Demo Bank',
        bankAccountName: 'Demo User',
      );

      if (!created) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Demo setup failed: ${merchantProvider.error ?? 'unknown'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Ensure merchant data is loaded
        await merchantProvider.loadUserMerchants();
        // Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo sign-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDemoSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider?>(
            builder: (context, authProvider, _) {
              final ap = authProvider; // nullable alias
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo and Title
                    Column(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: const MetartPayLogo(
                            height: 50,
                            isDarkBackground: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MetartPay',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crypto payments made simple',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: ap?.isLoading == true ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: ap?.isLoading == true
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // OR Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Google Sign-in Button
                    OutlinedButton.icon(
                      onPressed: ap?.isLoading == true
                          ? null
                          : () => _loginWithGoogle(),
                      icon: SizedBox(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          'assets/icons/google.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to 'G' if image fails to load
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: Colors.white,
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Debug-only: Sign in as Demo
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isDemoSigning ? null : _signInAsDemo,
                        icon: _isDemoSigning
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bug_report),
                        label: const Text('Sign in as Demo (debug)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 40),

                    // Footer
                    Text(
                      'Secure crypto payment processing',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
