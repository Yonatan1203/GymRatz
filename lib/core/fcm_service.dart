import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Top-level background message handler — must be a free function, not a method.
/// Runs in an isolate when the app is terminated or backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // flutter_local_notifications cannot be used in background isolates on all
  // platforms, so we rely on FCM's native notification display for data-only
  // messages. Structured payloads can be processed here if needed.
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once at app startup (before runApp) to register the background handler.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after the user logs in to request permission, get token, and wire handlers.
  /// [onTokenRefresh] is called with the current token and on every refresh.
  Future<void> initialize({
    required Future<void> Function(String token) onTokenRefresh,
  }) async {
    // Request notification permission — iOS prompts, Android 13+ prompts.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: notification permission denied');
      return;
    }

    // iOS: get APNs token first (required before FCM token on iOS).
    if (Platform.isIOS) {
      await _messaging.getAPNSToken();
    }

    // Get and persist current token.
    final token = await _messaging.getToken();
    if (token != null) {
      await onTokenRefresh(token);
    }

    // Persist new token whenever FCM rotates it.
    _messaging.onTokenRefresh.listen(onTokenRefresh);

    // Foreground messages: display as local notification.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from a notification in the background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App launched from a terminated state via notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    NotificationService().showFcmNotification(
      title: notification.title ?? 'GymRatz',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Route deep-linking: Cloud Functions include a 'route' key in data payload.
    final route = message.data['route'] as String?;
    if (route != null) {
      debugPrint('FCM tap → navigate to: $route');
      // Actual navigation is handled by the router on next build; store if needed.
    }
  }
}
