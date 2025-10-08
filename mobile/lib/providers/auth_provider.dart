import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/security_service.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecurityService _securityService = SecurityService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }
  
  void _initializeAuth() {
    try {
      _auth = FirebaseAuth.instance;
      _auth?.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
      print('✅ DEBUG: AuthProvider initialized with Firebase Auth');
    } catch (e) {
      print('❌ DEBUG: AuthProvider failed to initialize Firebase Auth: $e');
      _setError('Firebase Auth not available');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_auth == null) {
        print('❌ DEBUG: Firebase Auth not initialized for login');
        _setError('Firebase Auth not available');
        return false;
      }

      print('🔍 DEBUG: Starting login for email: $email');

      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ DEBUG: Login successful!');
      
      // Create security session
      if (userCredential.user != null) {
        try {
          await _securityService.createSession(userId: userCredential.user!.uid);
          print('✅ DEBUG: Security session created');
        } catch (e) {
          print('⚠️ DEBUG: Failed to create security session: $e');
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Login FirebaseAuthException');
      print('❌ DEBUG: Error code: ${e.code}');
      print('❌ DEBUG: Error message: ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid login credentials.';
          break;
        default:
          errorMessage = 'Login error: ${e.code} - ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      print('❌ DEBUG: Login general exception: $e');
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_auth == null) {
        print('❌ DEBUG: Firebase Auth not initialized');
        _setError('Firebase Auth not available');
        return false;
      }

      print('🔍 DEBUG: Starting registration for email: $email');
      print('🔍 DEBUG: Firebase Auth instance: ${_auth.toString()}');
      print('🔍 DEBUG: Current user: ${_auth?.currentUser?.email ?? 'None'}');

      UserCredential result = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ DEBUG: Registration successful!');
      print('✅ DEBUG: User UID: ${result.user?.uid}');
      print('✅ DEBUG: User email: ${result.user?.email}');

      // Update user profile with name
      await result.user?.updateDisplayName(name);
      print('✅ DEBUG: Display name updated to: $name');

      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: FirebaseAuthException caught');
      print('❌ DEBUG: Error code: ${e.code}');
      print('❌ DEBUG: Error message: ${e.message}');
      print('❌ DEBUG: Stack trace: ${e.stackTrace}');
      
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your internet connection.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Error: ${e.code} - ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      print('❌ DEBUG: General exception caught');
      print('❌ DEBUG: Exception: $e');
      print('❌ DEBUG: Exception type: ${e.runtimeType}');
      _setError('Unexpected error: $e');
      return false;
    } finally {
      print('🔍 DEBUG: Registration attempt completed');
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential? userCredential;
      if (_auth != null) {
        userCredential = await _auth!.signInWithCredential(credential);
      } else {
        _setError('Firebase Auth not available for Google Sign-in');
        return false;
      }
      
      // Create security session
      if (userCredential?.user != null) {
        try {
          await _securityService.createSession(userId: userCredential!.user!.uid);
          print('✅ DEBUG: Security session created for Google sign-in');
        } catch (e) {
          print('⚠️ DEBUG: Failed to create security session: $e');
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with the same email but different sign-in credentials.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'This sign-in method is not allowed.';
          break;
        case 'user-disabled':
          errorMessage = 'The user account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred during Google sign-in.';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during Google sign-in.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      // End security session first
      try {
        await _securityService.endSession(reason: 'user_logout');
        print('✅ DEBUG: Security session ended');
      } catch (e) {
        print('⚠️ DEBUG: Failed to end security session: $e');
      }
      
      if (_auth != null) {
        await Future.wait([
          _auth!.signOut(),
          _googleSignIn.signOut(),
        ]);
      } else {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      _setError('Error signing out.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_auth != null) {
        await _auth!.sendPasswordResetEmail(email: email);
      } else {
        _setError('Firebase Auth not available for password reset');
        return;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _setError(errorMessage);
    } catch (e) {
      _setError('An unexpected error occurred.');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}