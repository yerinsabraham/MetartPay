import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  final BiometricService _biometricService = BiometricService();

  // Session Management
  List<UserSession> _activeSessions = [];
  UserSession? _currentSession;
  bool _sessionLoading = false;

  // Security Logs
  List<SecurityLog> _securityLogs = [];
  bool _logsLoading = false;

  // Security Alerts
  List<SecurityAlert> _securityAlerts = [];
  bool _alertsLoading = false;

  // Biometric Settings
  BiometricSettings? _biometricSettings;
  BiometricCapability? _biometricCapability;
  bool _biometricLoading = false;

  // Getters
  List<UserSession> get activeSessions => _activeSessions;
  UserSession? get currentSession => _currentSession;
  bool get sessionLoading => _sessionLoading;

  List<SecurityLog> get securityLogs => _securityLogs;
  bool get logsLoading => _logsLoading;

  List<SecurityAlert> get securityAlerts => _securityAlerts;
  bool get alertsLoading => _alertsLoading;

  BiometricSettings? get biometricSettings => _biometricSettings;
  BiometricCapability? get biometricCapability => _biometricCapability;
  bool get biometricLoading => _biometricLoading;

  bool get hasCriticalAlerts => _securityAlerts.any((alert) => alert.severity == 'critical');
  bool get hasHighAlerts => _securityAlerts.any((alert) => alert.severity == 'high');
  int get totalAlerts => _securityAlerts.length;

  // Initialize security provider
  Future<void> initialize() async {
    await _securityService.initialize();
    await loadBiometricCapability();
  }

  // Session Management Methods
  Future<void> loadActiveSessions(String userId) async {
    _sessionLoading = true;
    notifyListeners();

    try {
      _activeSessions = await _securityService.getActiveSessions(userId);
      _currentSession = _activeSessions.firstWhere(
        (session) => session.id == _securityService.currentSessionId,
        orElse: () => _activeSessions.isNotEmpty ? _activeSessions.first : _activeSessions.first,
      );
    } catch (e) {
        debugPrint('Error loading active sessions: $e');
      _activeSessions = [];
      _currentSession = null;
    }

    _sessionLoading = false;
    notifyListeners();
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _securityService.endSpecificSession(sessionId, reason: 'terminated_by_user');
      
      // Reload sessions
      if (_currentSession != null) {
        await loadActiveSessions(_currentSession!.userId);
      }
    } catch (e) {
        debugPrint('Error ending session: $e');
    }
  }

  Future<void> endAllOtherSessions(String userId) async {
    try {
      await _securityService.endAllOtherSessions(userId);
      await loadActiveSessions(userId);
    } catch (e) {
        debugPrint('Error ending all other sessions: $e');
    }
  }

  Future<bool> refreshCurrentSession() async {
    try {
      return await _securityService.refreshSession();
    } catch (e) {
        debugPrint('Error refreshing session: $e');
      return false;
    }
  }

  // Security Logs Methods
  Future<void> loadSecurityLogs(String userId, {
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    _logsLoading = true;
    notifyListeners();

    try {
      _securityLogs = await _securityService.getSecurityLogs(
        userId,
        severity: severity,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
        debugPrint('Error loading security logs: $e');
      _securityLogs = [];
    }

    _logsLoading = false;
    notifyListeners();
  }

  Future<void> logSecurityEvent({
    required String userId,
    required String eventType,
    required String eventDescription,
    required String severity,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      await _securityService.logSecurityEvent(
        userId: userId,
        sessionId: _securityService.currentSessionId ?? 'unknown',
        eventType: eventType,
        eventDescription: eventDescription,
        severity: severity,
        eventData: eventData,
      );

      // Reload logs if they're currently loaded
      if (_securityLogs.isNotEmpty) {
        await loadSecurityLogs(userId);
      }
    } catch (e) {
        debugPrint('Error logging security event: $e');
    }
  }

  // Security Alerts Methods
  Future<void> loadSecurityAlerts(String userId) async {
    _alertsLoading = true;
    notifyListeners();

    try {
      _securityAlerts = await _securityService.detectSuspiciousActivity(userId);
    } catch (e) {
        debugPrint('Error loading security alerts: $e');
      _securityAlerts = [];
    }

    _alertsLoading = false;
    notifyListeners();
  }

  void clearSecurityAlerts() {
    _securityAlerts.clear();
    notifyListeners();
  }

  // Biometric Methods
  Future<void> loadBiometricCapability() async {
    _biometricLoading = true;
    notifyListeners();

    try {
      _biometricCapability = await _biometricService.getBiometricCapability();
    } catch (e) {
        debugPrint('Error loading biometric capability: $e');
      _biometricCapability = null;
    }

    _biometricLoading = false;
    notifyListeners();
  }

  Future<BiometricAuthResult> enableBiometric(String reason) async {
    final result = await _biometricService.enableBiometric(reason);
    
    if (result.isSuccess) {
      await loadBiometricCapability();
    }
    
    return result;
  }

  Future<void> disableBiometric() async {
    await _biometricService.disableBiometric();
    await loadBiometricCapability();
  }

  Future<BiometricAuthResult> authenticateWithBiometric(String reason) async {
    return await _biometricService.authenticate(reason: reason);
  }

  Future<bool> quickBiometricAuth(String reason) async {
    return await _biometricService.quickAuthenticate(reason);
  }

  Future<void> resetBiometricLockout() async {
    await _biometricService.resetLockout();
    await loadBiometricCapability();
  }

  // Helper methods
  String getSessionRiskLevel(UserSession session) {
    final now = DateTime.now();
    final sessionAge = now.difference(session.loginTime).inHours;
    final lastActivityAge = now.difference(session.lastActivity ?? session.loginTime).inHours;
    
    // High risk if session is very old or has been inactive for a long time
    if (sessionAge > 168 || lastActivityAge > 24) { // 7 days or 24 hours inactive
      return 'high';
    }
    
    // Medium risk if session is moderately old
    if (sessionAge > 72 || lastActivityAge > 12) { // 3 days or 12 hours inactive
      return 'medium';
    }
    
    return 'low';
  }

  String getLogSeverityColor(SecurityLog log) {
    return log.severityColor;
  }

  String getAlertSeverityColor(SecurityAlert alert) {
    return alert.severityColor;
  }

  List<SecurityLog> getLogsByType(String eventType) {
    return _securityLogs.where((log) => log.eventType == eventType).toList();
  }

  List<SecurityLog> getLogsBySeverity(String severity) {
    return _securityLogs.where((log) => log.severity == severity).toList();
  }

  List<SecurityAlert> getAlertsBySeverity(String severity) {
    return _securityAlerts.where((alert) => alert.severity == severity).toList();
  }

  Map<String, int> getLogStatistics() {
    final Map<String, int> stats = {
      'total': _securityLogs.length,
      'critical': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    for (final log in _securityLogs) {
      stats[log.severity] = (stats[log.severity] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> getAlertStatistics() {
    final Map<String, int> stats = {
      'total': _securityAlerts.length,
      'critical': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    for (final alert in _securityAlerts) {
      stats[alert.severity] = (stats[alert.severity] ?? 0) + 1;
    }

    return stats;
  }

  // Session monitoring
  Future<void> updateSessionActivity() async {
    await _securityService.updateSessionActivity();
  }

  Future<bool> validateSession() async {
    return await _securityService.validateCurrentSession();
  }

  // Refresh all data
  Future<void> refreshAllData(String userId) async {
    await Future.wait([
      loadActiveSessions(userId),
      loadSecurityLogs(userId),
      loadSecurityAlerts(userId),
      loadBiometricCapability(),
    ]);
  }

  // Aliases for biometric methods to match usage in screens
  Future<void> checkBiometricCapability() async {
    await loadBiometricCapability();
  }

  Future<BiometricAuthResult> authenticateWithBiometrics(String reason) async {
    return await authenticateWithBiometric(reason);
  }
}