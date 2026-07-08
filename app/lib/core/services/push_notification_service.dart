import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Callback for handling notification taps (deep linking).
/// Set this from the app's main widget to enable navigation.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

/// Handles FCM token registration, background messages, and notification taps.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static NotificationTapCallback? onNotificationTap;

  /// Initialize push notifications: request permissions, register token, handle taps.
  static Future<void> initialize() async {
    // Request permission (iOS requires explicit permission)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info('Push notification permission', data: {
      'status': settings.authorizationStatus.name,
    });

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
      _listenForTokenRefresh();
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to let the app finish building
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  /// Get and store the FCM token.
  static Future<void> _registerToken() async {
    try {
      String? token;
      if (kIsWeb) {
        // Web requires VAPID key — skip if not configured
        return;
      } else {
        token = await _messaging.getToken();
      }
      if (token == null) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('userTokens')
          .doc(userId)
          .set({
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.info('FCM token registered', data: {'userId': userId});
    } catch (e) {
      AppLogger.error('Failed to register FCM token', error: e);
    }
  }

  /// Listen for token refreshes and update Firestore.
  static void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('userTokens')
          .doc(userId)
          .update({
        'fcmToken': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('FCM token refreshed');
    });
  }

  /// Handle messages received while app is in foreground.
  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Foreground message received', data: {
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
    // Foreground messages update the badge via Firestore stream (automatic)
  }

  /// Handle notification tap (app was in background or terminated).
  static void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notification tapped', data: {'data': message.data});
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }

  /// Subscribe to household topic for group notifications.
  static Future<void> subscribeToHousehold(String householdId) async {
    await _messaging.subscribeToTopic('household_$householdId');
  }

  /// Unsubscribe from household topic.
  static Future<void> unsubscribeFromHousehold(String householdId) async {
    await _messaging.unsubscribeFromTopic('household_$householdId');
  }
}

/// Top-level background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}
