import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/models.dart';
import '../utils/app_logger.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const String _currentSessionKey = 'current_session';
  static const String _deviceIdKey = 'device_id';
  static const String _sessionTokenKey = 'session_token';

  String? _currentSessionId;
  String? _deviceId;
  
  // Initialize security service
  Future<void> initialize() async {
    _deviceId = await _getOrCreateDeviceId();
    await _loadCurrentSession();
  }

  // Create new session on login
  Future<UserSession> createSession({
    required String userId,
    String? customLocation,
  }) async {
    final sessionId = _generateSessionId();
    final deviceInfo = await _getDeviceInfo();
    final packageInfo = await PackageInfo.fromPlatform();
    
    final session = UserSession(
      id: sessionId,
      userId: userId,
      deviceId: _deviceId!,
      deviceName: deviceInfo['deviceName'] ?? 'Unknown Device',
      deviceModel: deviceInfo['deviceModel'] ?? 'Unknown Model',
      operatingSystem: deviceInfo['operatingSystem'] ?? 'Unknown OS',
      appVersion: packageInfo.version,
      ipAddress: await _getIPAddress(),
      location: customLocation ?? 'Unknown',
      loginTime: DateTime.now(),
      lastActivity: DateTime.now(),
      isActive: true,
      sessionToken: _generateSessionToken(),
      metadata: {
        'appBuild': packageInfo.buildNumber,
        'platform': Platform.operatingSystem,
        'userAgent': deviceInfo['userAgent'] ?? '',
      },
    );

    // Store session in Firestore
    await _firestore
        .collection('user_sessions')
        .doc(sessionId)
        .set(session.toJson());

    // Store current session locally
    await _storeCurrentSession(session);
    
    // Log security event
    await logSecurityEvent(
      userId: userId,
      sessionId: sessionId,
      eventType: 'login',
      eventDescription: 'User logged in successfully',
      severity: 'low',
    );

    _currentSessionId = sessionId;
    return session;
  }

  // Update session activity
  Future<void> updateSessionActivity() async {
    if (_currentSessionId == null) return;

    try {
      await _firestore
          .collection('user_sessions')
          .doc(_currentSessionId!)
          .update({
        'lastActivity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.e('Error updating session activity', error: e);
    }
  }

  // End current session
  Future<void> endSession({String? reason}) async {
    if (_currentSessionId == null) return;

    try {
      await _firestore
          .collection('user_sessions')
          .doc(_currentSessionId!)
          .update({
        'isActive': false,
        'logoutTime': DateTime.now().toIso8601String(),
        'metadata.logoutReason': reason ?? 'user_logout',
      });

      // Log security event
      if (_auth.currentUser != null) {
        await logSecurityEvent(
          userId: _auth.currentUser!.uid,
          sessionId: _currentSessionId!,
          eventType: 'logout',
          eventDescription: 'User session ended: ${reason ?? 'user_logout'}',
          severity: 'low',
        );
      }

      // Clear local session data
      await _clearCurrentSession();
      _currentSessionId = null;
    } catch (e) {
      AppLogger.e('Error ending session', error: e);
    }
  }

  // Get active sessions for user
  Future<List<UserSession>> getActiveSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('loginTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserSession.fromJson(doc.data()))
          .where((session) => !session.isExpired())
          .toList();
    } catch (e) {
      AppLogger.e('Error getting active sessions', error: e);
      return [];
    }
  }

  // End specific session
  Future<void> endSpecificSession(String sessionId, {String? reason}) async {
    try {
      await _firestore
          .collection('user_sessions')
          .doc(sessionId)
          .update({
        'isActive': false,
        'logoutTime': DateTime.now().toIso8601String(),
        'metadata.logoutReason': reason ?? 'terminated_by_user',
      });

      // If ending current session, clear local data
      if (sessionId == _currentSessionId) {
        await _clearCurrentSession();
        _currentSessionId = null;
      }
    } catch (e) {
      AppLogger.e('Error ending specific session', error: e);
    }
  }

  // End all other sessions (keep current)
  Future<void> endAllOtherSessions(String userId) async {
    try {
      final activeSessions = await getActiveSessions(userId);
      
      for (final session in activeSessions) {
        if (session.id != _currentSessionId) {
          await endSpecificSession(session.id, reason: 'terminated_by_user_all_sessions');
        }
      }

      // Log security event
      await logSecurityEvent(
        userId: userId,
        sessionId: _currentSessionId ?? 'unknown',
        eventType: 'session_management',
        eventDescription: 'User terminated all other sessions',
        severity: 'medium',
      );
    } catch (e) {
      AppLogger.e('Error ending all other sessions', error: e);
    }
  }

  // Log security event
  Future<void> logSecurityEvent({
    required String userId,
    required String sessionId,
    required String eventType,
    required String eventDescription,
    required String severity,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      final securityLog = SecurityLog(
        id: _generateLogId(),
        userId: userId,
        sessionId: sessionId,
        eventType: eventType,
        eventDescription: eventDescription,
        severity: severity,
        deviceId: _deviceId!,
        ipAddress: await _getIPAddress(),
        location: 'Unknown', // Could be enhanced with location services
        eventData: eventData ?? {},
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('security_logs')
          .doc(securityLog.id)
          .set(securityLog.toJson());
    } catch (e) {
      AppLogger.e('Error logging security event', error: e);
    }
  }

  // Get security logs for user
  Future<List<SecurityLog>> getSecurityLogs(
    String userId, {
    int limit = 50,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => SecurityLog.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting security logs', error: e);
      return [];
    }
  }

  // Detect suspicious activity
  Future<List<SecurityAlert>> detectSuspiciousActivity(String userId) async {
    final List<SecurityAlert> alerts = [];
    
    try {
      // Check for multiple failed login attempts
      await _checkFailedLoginAttempts(userId, alerts);
      
      // Check for logins from new devices
      await _checkNewDeviceLogins(userId, alerts);
      
      // Check for unusual transaction patterns
      await _checkUnusualTransactionActivity(userId, alerts);
      
      // Check for concurrent sessions from different locations
      await _checkConcurrentSessions(userId, alerts);
      
    } catch (e) {
      AppLogger.e('Error detecting suspicious activity', error: e);
    }
    
    return alerts;
  }

  // Validate current session
  Future<bool> validateCurrentSession() async {
    if (_currentSessionId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('user_sessions')
          .doc(_currentSessionId!)
          .get();
      
      if (!doc.exists) return false;
      
      final session = UserSession.fromJson(doc.data()!);
      return session.isActive && !session.isExpired();
    } catch (e) {
      AppLogger.e('Error validating session', error: e);
      return false;
    }
  }

  // Force session refresh
  Future<bool> refreshSession() async {
    if (_auth.currentUser == null) return false;
    
    // End current session if exists
    await endSession(reason: 'session_refresh');
    
    // Create new session
    final newSession = await createSession(userId: _auth.currentUser!.uid);
    return newSession.isActive;
  }

  // Private helper methods
  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      final deviceInfo = await _getDeviceInfo();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final input = '${deviceInfo['deviceModel']}_${deviceInfo['deviceName']}_$timestamp';
      
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      deviceId = digest.toString().substring(0, 16);
      
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'deviceName': androidInfo.model,
          'deviceModel': '${androidInfo.brand} ${androidInfo.model}',
          'operatingSystem': 'Android ${androidInfo.version.release}',
          'userAgent': 'Android/${androidInfo.version.release} ${androidInfo.brand}/${androidInfo.model}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceName': iosInfo.name,
          'deviceModel': '${iosInfo.model} ${iosInfo.systemName}',
          'operatingSystem': '${iosInfo.systemName} ${iosInfo.systemVersion}',
          'userAgent': '${iosInfo.systemName}/${iosInfo.systemVersion} ${iosInfo.model}',
        };
      } else {
        return {
          'deviceName': 'Unknown Device',
          'deviceModel': 'Unknown Model',
          'operatingSystem': Platform.operatingSystem,
          'userAgent': Platform.operatingSystem,
        };
      }
    } catch (e) {
      AppLogger.e('Error getting device info', error: e);
      return {
        'deviceName': 'Unknown Device',
        'deviceModel': 'Unknown Model',
        'operatingSystem': Platform.operatingSystem,
        'userAgent': Platform.operatingSystem,
      };
    }
  }

  Future<String> _getIPAddress() async {
    // In a real app, you'd get the actual IP address
    // For now, return a placeholder
    return '0.0.0.0';
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode + _deviceId.hashCode).toString();
    final bytes = utf8.encode('$timestamp:$random');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = timestamp.hashCode.toString();
    final bytes = utf8.encode('$timestamp:$random:${_deviceId}');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$timestamp:${_deviceId}');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 24);
  }

  Future<void> _storeCurrentSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, session.id);
    await _secureStorage.write(key: _sessionTokenKey, value: session.sessionToken);
  }

  Future<void> _loadCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = prefs.getString(_currentSessionKey);
  }

  Future<void> _clearCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
    await _secureStorage.delete(key: _sessionTokenKey);
  }

  // Suspicious activity detection methods
  Future<void> _checkFailedLoginAttempts(String userId, List<SecurityAlert> alerts) async {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    
    final logs = await getSecurityLogs(
      userId,
      startDate: oneDayAgo,
    );
    
    final failedAttempts = logs.where((log) => 
      log.eventType == 'failed_login' || 
      log.eventDescription.toLowerCase().contains('failed')
    ).length;
    
    if (failedAttempts >= 5) {
      alerts.add(SecurityAlert(
        type: 'multiple_failed_attempts',
        severity: 'high',
        message: 'Multiple failed login attempts detected ($failedAttempts in the last 24 hours)',
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _checkNewDeviceLogins(String userId, List<SecurityAlert> alerts) async {
    // This is simplified - in production, you'd track known devices
    final sessions = await getActiveSessions(userId);
    final uniqueDevices = sessions.map((s) => s.deviceId).toSet();
    
    if (uniqueDevices.length > 3) {
      alerts.add(SecurityAlert(
        type: 'multiple_devices',
        severity: 'medium',
        message: 'Account accessed from ${uniqueDevices.length} different devices',
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _checkUnusualTransactionActivity(String userId, List<SecurityAlert> alerts) async {
    // This would integrate with transaction data
    // For now, it's a placeholder
  }

  Future<void> _checkConcurrentSessions(String userId, List<SecurityAlert> alerts) async {
    final sessions = await getActiveSessions(userId);
    
    if (sessions.length > 2) {
      alerts.add(SecurityAlert(
        type: 'concurrent_sessions',
        severity: 'medium',
        message: 'Multiple active sessions detected (${sessions.length} sessions)',
        timestamp: DateTime.now(),
      ));
    }
  }

  // Get current session ID
  String? get currentSessionId => _currentSessionId;
  
  // Get device ID
  String? get deviceId => _deviceId;
}

// Security alert model
class SecurityAlert {
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SecurityAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.data = const {},
  });

  String get severityColor {
    switch (severity) {
      case 'critical':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }
}