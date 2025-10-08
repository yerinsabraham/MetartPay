import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _failedAttemptsKey = 'biometric_failed_attempts';
  static const String _lockoutEndTimeKey = 'biometric_lockout_end_time';
  static const String _biometricTokenKey = 'biometric_token';

  // Check if biometric authentication is available on device
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  // Check if biometrics are enrolled on the device
  Future<bool> areBiometricsEnrolled() async {
    try {
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometrics enrollment: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if user has enabled biometric authentication in app
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    
    if (!enabled) {
      // Clear biometric token when disabled
      await _secureStorage.delete(key: _biometricTokenKey);
      await _clearFailedAttempts();
    }
  }

  // Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if device is in lockout
      if (await _isInLockout()) {
        final lockoutEnd = await _getLockoutEndTime();
        final remainingTime = lockoutEnd?.difference(DateTime.now()) ?? Duration.zero;
        return BiometricAuthResult.lockout(remainingTime);
      }

      // Check if biometric is enabled
      if (!await isBiometricEnabled()) {
        return BiometricAuthResult.disabled();
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device Credentials Required',
            deviceCredentialsSetupDescription: 'Device credentials are not set up on your device. Go to Settings > Security to set up.',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up biometric authentication on your device to use this feature.',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up biometric authentication on your device to use this feature.',
            lockOut: 'Biometric authentication is locked. Please use device passcode.',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
        ),
      );

      if (didAuthenticate) {
        await _clearFailedAttempts();
        await _storeBiometricToken();
        return BiometricAuthResult.success();
      } else {
        await _incrementFailedAttempts();
        return BiometricAuthResult.failed();
      }
    } on PlatformException catch (e) {
      await _incrementFailedAttempts();
      return BiometricAuthResult.error(e.message ?? 'Authentication error');
    } catch (e) {
      return BiometricAuthResult.error('Unexpected error: $e');
    }
  }

  // Quick authentication without detailed error handling
  Future<bool> quickAuthenticate(String reason) async {
    final result = await authenticate(reason: reason);
    return result.isSuccess;
  }

  // Store biometric authentication token
  Future<void> _storeBiometricToken() async {
    final token = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: _biometricTokenKey, value: token);
  }

  // Get biometric token
  Future<String?> getBiometricToken() async {
    return await _secureStorage.read(key: _biometricTokenKey);
  }

  // Clear biometric token
  Future<void> clearBiometricToken() async {
    await _secureStorage.delete(key: _biometricTokenKey);
  }

  // Increment failed attempts
  Future<void> _incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final currentAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    final newAttempts = currentAttempts + 1;
    
    await prefs.setInt(_failedAttemptsKey, newAttempts);
    
    // Apply lockout if max attempts reached
    if (newAttempts >= 3) {
      final lockoutEnd = DateTime.now().add(const Duration(minutes: 5));
      await prefs.setString(_lockoutEndTimeKey, lockoutEnd.toIso8601String());
    }
  }

  // Clear failed attempts
  Future<void> _clearFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutEndTimeKey);
  }

  // Get failed attempts count
  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  // Check if in lockout
  Future<bool> _isInLockout() async {
    final lockoutEnd = await _getLockoutEndTime();
    if (lockoutEnd == null) return false;
    return DateTime.now().isBefore(lockoutEnd);
  }

  // Get lockout end time
  Future<DateTime?> _getLockoutEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutStr = prefs.getString(_lockoutEndTimeKey);
    if (lockoutStr == null) return null;
    return DateTime.parse(lockoutStr);
  }

  // Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime() async {
    final lockoutEnd = await _getLockoutEndTime();
    if (lockoutEnd == null) return null;
    
    final remaining = lockoutEnd.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // Reset lockout
  Future<void> resetLockout() async {
    await _clearFailedAttempts();
  }

  // Get biometric capability info
  Future<BiometricCapability> getBiometricCapability() async {
    final isSupported = await isDeviceSupported();
    final isEnrolled = await areBiometricsEnrolled();
    final availableTypes = await getAvailableBiometrics();
    final isEnabled = await isBiometricEnabled();
    
    return BiometricCapability(
      isSupported: isSupported,
      isEnrolled: isEnrolled,
      availableTypes: availableTypes,
      isEnabled: isEnabled,
    );
  }

  // Enable biometric with verification
  Future<BiometricAuthResult> enableBiometric(String reason) async {
    final capability = await getBiometricCapability();
    
    if (!capability.isSupported) {
      return BiometricAuthResult.error('Biometric authentication is not supported on this device');
    }
    
    if (!capability.isEnrolled) {
      return BiometricAuthResult.error('No biometrics are enrolled on this device. Please set up biometrics in device settings.');
    }
    
    final result = await authenticate(reason: reason);
    if (result.isSuccess) {
      await setBiometricEnabled(true);
    }
    
    return result;
  }

  // Disable biometric
  Future<void> disableBiometric() async {
    await setBiometricEnabled(false);
  }
}

// Authentication result classes
class BiometricAuthResult {
  final bool isSuccess;
  final bool isError;
  final bool isLockout;
  final bool isDisabled;
  final String? errorMessage;
  final Duration? lockoutDuration;

  BiometricAuthResult._({
    required this.isSuccess,
    required this.isError,
    required this.isLockout,
    required this.isDisabled,
    this.errorMessage,
    this.lockoutDuration,
  });

  factory BiometricAuthResult.success() => BiometricAuthResult._(
    isSuccess: true,
    isError: false,
    isLockout: false,
    isDisabled: false,
  );

  factory BiometricAuthResult.failed() => BiometricAuthResult._(
    isSuccess: false,
    isError: false,
    isLockout: false,
    isDisabled: false,
  );

  factory BiometricAuthResult.error(String message) => BiometricAuthResult._(
    isSuccess: false,
    isError: true,
    isLockout: false,
    isDisabled: false,
    errorMessage: message,
  );

  factory BiometricAuthResult.lockout(Duration duration) => BiometricAuthResult._(
    isSuccess: false,
    isError: false,
    isLockout: true,
    isDisabled: false,
    lockoutDuration: duration,
  );

  factory BiometricAuthResult.disabled() => BiometricAuthResult._(
    isSuccess: false,
    isError: false,
    isLockout: false,
    isDisabled: true,
  );
}

// Biometric capability info
class BiometricCapability {
  final bool isSupported;
  final bool isEnrolled;
  final List<BiometricType> availableTypes;
  final bool isEnabled;

  BiometricCapability({
    required this.isSupported,
    required this.isEnrolled,
    required this.availableTypes,
    required this.isEnabled,
  });

  bool get canUseBiometric => isSupported && isEnrolled;
  bool get hasFingerprint => availableTypes.contains(BiometricType.fingerprint);
  bool get hasFace => availableTypes.contains(BiometricType.face);
  bool get hasIris => availableTypes.contains(BiometricType.iris);
  
  String get availableTypesDescription {
    if (availableTypes.isEmpty) return 'None';
    
    List<String> types = [];
    if (hasFingerprint) types.add('Fingerprint');
    if (hasFace) types.add('Face');
    if (hasIris) types.add('Iris');
    
    return types.join(', ');
  }
}