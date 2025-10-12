import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _fcmToken;
  String? _currentMerchantId;
  
  // Notification handlers
  Function(AppNotification)? onNotificationReceived;
  Function(AppNotification)? onNotificationTapped;
  Function(String)? onTokenRefresh;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize({String? merchantId}) async {
    AppLogger.d('NotificationService: Initializing FCM...');
    
    try {
      _currentMerchantId = merchantId;
      
      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.d('NotificationService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        await _getFCMToken();
        
        // Configure message handlers
        _configureMessageHandlers();
        
        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((token) {
          AppLogger.d('NotificationService: Token refreshed: $token');
          _fcmToken = token;
          _saveFCMToken(token);
          if (_currentMerchantId != null) {
            _updateTokenOnServer(token, _currentMerchantId!);
          }
          onTokenRefresh?.call(token);
        });
        
        AppLogger.d('NotificationService: FCM initialized successfully');
      } else {
        AppLogger.w('NotificationService: Notification permission denied');
      }
    } catch (e) {
      AppLogger.e('NotificationService: Error initializing FCM: $e', error: e);
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    return await _getFCMToken();
  }

  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.d('NotificationService: FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
        if (_currentMerchantId != null) {
          await _updateTokenOnServer(_fcmToken!, _currentMerchantId!);
        }
      }
      
      return _fcmToken;
    } catch (e) {
      AppLogger.e('NotificationService: Error getting FCM token: $e', error: e);
      return null;
    }
  }

  /// Save FCM token locally
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      AppLogger.e('NotificationService: Error saving FCM token: $e', error: e);
    }
  }

  /// Update FCM token on server
  Future<void> _updateTokenOnServer(String token, String merchantId) async {
    try {
      await _firestore.collection('fcm_tokens').doc(merchantId).set({
        'token': token,
        'merchantId': merchantId,
        'platform': 'android', // Could be dynamic based on platform
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      
      AppLogger.d('NotificationService: Token updated on server');
    } catch (e) {
      AppLogger.e('NotificationService: Error updating token on server: $e', error: e);
    }
  }

  /// Configure message handlers
  void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.d('NotificationService: Received foreground message: ${message.messageId}');
      _handleMessage(message, isForeground: true);
    });

    // Handle messages when app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('NotificationService: App opened from notification: ${message.messageId}');
      _handleMessage(message, isFromTap: true);
    });

    // Handle messages when app is terminated and opened from notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.d('NotificationService: App launched from notification: ${message.messageId}');
        _handleMessage(message, isFromTap: true);
      }
    });
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message, {bool isForeground = false, bool isFromTap = false}) {
    try {
      final notification = _convertToAppNotification(message);
      
      if (isForeground) {
        // Show in-app notification
        _showInAppNotification(notification);
        onNotificationReceived?.call(notification);
      }
      
      if (isFromTap) {
        // Handle notification tap
        onNotificationTapped?.call(notification);
      }
      
      // Save notification to local storage/database
      _saveNotification(notification);
      
    } catch (e) {
      AppLogger.e('NotificationService: Error handling message: $e', error: e);
    }
  }

  /// Convert Firebase message to AppNotification
  AppNotification _convertToAppNotification(RemoteMessage message) {
    final data = message.data;
    
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      merchantId: data['merchantId'] ?? _currentMerchantId ?? '',
      type: data['type'] ?? 'system',
      title: message.notification?.title ?? data['title'] ?? 'Notification',
      body: message.notification?.body ?? data['body'] ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? data['imageUrl'],
      data: data.isNotEmpty ? data : null,
      priority: data['priority'] ?? 'normal',
      createdAt: DateTime.now(),
      actionUrl: data['actionUrl'],
      actionText: data['actionText'],
    );
  }

  /// Show in-app notification (custom implementation)
  void _showInAppNotification(AppNotification notification) {
    // This would typically show a custom in-app notification widget
    // For now, we'll just trigger the callback
    AppLogger.d('NotificationService: Showing in-app notification: ${notification.title}');
  }

  /// Save notification to Firestore
  Future<void> _saveNotification(AppNotification notification) async {
    if (_currentMerchantId == null) return;
    
    try {
      await _firestore
          .collection('merchants')
          .doc(_currentMerchantId!)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());
      
      AppLogger.d('NotificationService: Notification saved to Firestore');
    } catch (e) {
      AppLogger.e('NotificationService: Error saving notification: $e', error: e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.d('NotificationService: Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.e('NotificationService: Error subscribing to topic: $e', error: e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.d('NotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.e('NotificationService: Error unsubscribing from topic: $e', error: e);
    }
  }

  /// Get notifications from Firestore
  Future<List<AppNotification>> getNotifications({
    String? merchantId,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final id = merchantId ?? _currentMerchantId;
    if (id == null) return [];

    try {
      Query query = _firestore
          .collection('merchants')
          .doc(id)
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AppNotification.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      AppLogger.e('NotificationService: Error getting notifications: $e', error: e);
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_currentMerchantId == null) return;

    try {
      await _firestore
          .collection('merchants')
          .doc(_currentMerchantId!)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.d('NotificationService: Notification marked as read');
    } catch (e) {
      AppLogger.e('NotificationService: Error marking notification as read: $e', error: e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (_currentMerchantId == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection('merchants')
          .doc(_currentMerchantId!)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      AppLogger.d('NotificationService: All notifications marked as read');
    } catch (e) {
      AppLogger.e('NotificationService: Error marking all notifications as read: $e', error: e);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (_currentMerchantId == null) return;

    try {
      await _firestore
          .collection('merchants')
          .doc(_currentMerchantId!)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      AppLogger.d('NotificationService: Notification deleted');
    } catch (e) {
      AppLogger.e('NotificationService: Error deleting notification: $e', error: e);
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    if (_currentMerchantId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('merchants')
          .doc(_currentMerchantId!)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.e('NotificationService: Error getting unread count: $e', error: e);
      return 0;
    }
  }

  /// Get notification settings
  Future<MerchantNotificationSettings?> getNotificationSettings({String? merchantId}) async {
    final id = merchantId ?? _currentMerchantId;
    if (id == null) return null;

    try {
      final doc = await _firestore
          .collection('merchants')
          .doc(id)
          .collection('settings')
          .doc('notifications')
          .get();
      
      if (doc.exists) {
        return MerchantNotificationSettings.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'merchantId': id,
        });
      } else {
        // Return default settings
        return MerchantNotificationSettings(
          merchantId: id,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      AppLogger.e('NotificationService: Error getting notification settings: $e', error: e);
      return null;
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(MerchantNotificationSettings settings) async {
    try {
      await _firestore
          .collection('merchants')
          .doc(settings.merchantId)
          .collection('settings')
          .doc('notifications')
          .set(settings.toJson(), SetOptions(merge: true));
      
      AppLogger.d('NotificationService: Notification settings updated');
    } catch (e) {
      AppLogger.e('NotificationService: Error updating notification settings: $e', error: e);
    }
  }

  /// Send notification (for testing purposes)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    if (_currentMerchantId == null) return;

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      merchantId: _currentMerchantId!,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );

    await _saveNotification(notification);
    onNotificationReceived?.call(notification);
  }

  /// Set merchant ID
  void setMerchantId(String merchantId) {
    _currentMerchantId = merchantId;
    if (_fcmToken != null) {
      _updateTokenOnServer(_fcmToken!, merchantId);
    }
  }

  /// Clear merchant data (on logout)
  void clearMerchantData() {
    _currentMerchantId = null;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    try {
      await _firebaseMessaging.requestPermission();
    } catch (e) {
      AppLogger.e('NotificationService: Error opening notification settings: $e', error: e);
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.d('NotificationService: Background message received: ${message.messageId}');
  
  // Handle background message here if needed
  // Note: This runs in a separate isolate, so shared state is not available
}