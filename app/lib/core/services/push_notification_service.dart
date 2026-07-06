import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Handles FCM token registration and background message setup.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize push notifications: request permissions, register token.
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
  }

  /// Get and store the FCM token in the user's household document.
  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Store token under user document or household
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

    // TODO: Show in-app notification banner or navigate to relevant screen
  }

  /// Subscribe to household topic for group notifications.
  static Future<void> subscribeToHousehold(String householdId) async {
    await _messaging.subscribeToTopic('household_$householdId');
    AppLogger.info('Subscribed to household topic', data: {
      'householdId': householdId,
    });
  }

  /// Unsubscribe from household topic.
  static Future<void> unsubscribeFromHousehold(String householdId) async {
    await _messaging.unsubscribeFromTopic('household_$householdId');
  }
}

/// Top-level background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (e.g., update badge count)
  debugPrint('Background message: ${message.notification?.title}');
}
