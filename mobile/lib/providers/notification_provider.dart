import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  MerchantNotificationSettings? _settings;
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppNotification> get notifications => _notifications;
  MerchantNotificationSettings? get settings => _settings;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead && !n.isArchived).toList();
      
  List<AppNotification> get readNotifications => 
      _notifications.where((n) => n.isRead && !n.isArchived).toList();
      
  List<AppNotification> get archivedNotifications => 
      _notifications.where((n) => n.isArchived).toList();

  /// Initialize notification provider
  Future<void> initialize(String merchantId) async {
    AppLogger.d('NotificationProvider: Initializing for merchant: $merchantId');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Initialize notification service
      await _notificationService.initialize(merchantId: merchantId);
      
      // Set up listeners
      _notificationService.onNotificationReceived = _handleNotificationReceived;
      _notificationService.onNotificationTapped = _handleNotificationTapped;
      _notificationService.onTokenRefresh = _handleTokenRefresh;

      // Load initial data
      await Future.wait([
        loadNotifications(),
        loadNotificationSettings(),
        _updateUnreadCount(),
      ]);

    } catch (e) {
      _error = e.toString();
      AppLogger.e('NotificationProvider: Error initializing: $e', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notifications from service
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      if (refresh) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      _notifications = await _notificationService.getNotifications(limit: 100);
      await _updateUnreadCount();

    } catch (e) {
      _error = e.toString();
      AppLogger.e('NotificationProvider: Error loading notifications: $e', error: e);
    } finally {
      if (refresh) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Load notification settings
  Future<void> loadNotificationSettings() async {
    try {
      _settings = await _notificationService.getNotificationSettings();
      notifyListeners();
    } catch (e) {
      AppLogger.e('NotificationProvider: Error loading settings: $e', error: e);
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(MerchantNotificationSettings newSettings) async {
    try {
      await _notificationService.updateNotificationSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      AppLogger.e('NotificationProvider: Error updating settings: $e', error: e);
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        await _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('NotificationProvider: Error marking as read: $e', error: e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      
      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      AppLogger.e('NotificationProvider: Error marking all as read: $e', error: e);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      AppLogger.e('NotificationProvider: Error deleting notification: $e', error: e);
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      // Update local state (archive functionality would need server implementation)
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isArchived: true);
        await _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('NotificationProvider: Error archiving notification: $e', error: e);
    }
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    _unreadCount = _notifications.where((n) => !n.isRead && !n.isArchived).length;
  }

  /// Handle notification received
  void _handleNotificationReceived(AppNotification notification) {
    AppLogger.d('NotificationProvider: Notification received: ${notification.title}');
    
    // Add to beginning of list
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  /// Handle notification tapped
  void _handleNotificationTapped(AppNotification notification) {
    AppLogger.d('NotificationProvider: Notification tapped: ${notification.title}');
    
    // Mark as read if not already
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    
    // Handle action URL if present
    if (notification.actionUrl != null) {
      // Navigate to action URL (would need navigation context)
      AppLogger.d('NotificationProvider: Should navigate to: ${notification.actionUrl}');
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    AppLogger.d('NotificationProvider: FCM token refreshed: $token');
    // Could trigger any necessary updates here
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _notificationService.getFCMToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _notificationService.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationService.unsubscribeFromTopic(topic);
  }

  /// Send test notification
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    await _notificationService.sendTestNotification(
      title: title,
      body: body,
      type: type,
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }

  /// Filter notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type && !n.isArchived).toList();
  }

  /// Filter notifications by read status
  List<AppNotification> getNotificationsByReadStatus(bool isRead) {
    return _notifications.where((n) => n.isRead == isRead && !n.isArchived).toList();
  }

  /// Get notifications by priority
  List<AppNotification> getNotificationsByPriority(String priority) {
    return _notifications.where((n) => n.priority == priority && !n.isArchived).toList();
  }

  /// Get critical notifications
  List<AppNotification> getCriticalNotifications() {
    return _notifications.where((n) => n.isCritical && !n.isRead && !n.isArchived).toList();
  }

  /// Clear all data (on logout)
  void clearData() {
    _notifications.clear();
    _settings = null;
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _notificationService.clearMerchantData();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
    await loadNotificationSettings();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if notification exists
  bool hasNotification(String notificationId) {
    return _notifications.any((n) => n.id == notificationId);
  }

  /// Get notification by ID
  AppNotification? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere((n) => n.id == notificationId);
    } catch (e) {
      return null;
    }
  }
}