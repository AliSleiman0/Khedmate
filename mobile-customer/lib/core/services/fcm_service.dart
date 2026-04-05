import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Initialise [FlutterLocalNotificationsPlugin] — call once during app boot.
Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await _localNotifications.initialize(settings);

  // Create notification channel for Android
  const channel = AndroidNotificationChannel(
    'khudmati_channel',
    'Khudmati Notifications',
    description: 'Khudmati push notifications',
    importance: Importance.high,
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Shows a heads-up notification when the app is in foreground.
Future<void> showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  await _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'khudmati_channel',
        'Khudmati Notifications',
        channelDescription: 'Khudmati push notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

/// Registers the device's FCM token with the backend.
Future<void> registerFcmToken(ApiClient apiClient) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    await apiClient.dio.post(
      '/notifications/device-token',
      data: {'fcmToken': token, 'platform': platform},
    );
  } catch (_) {
    // Non-fatal — will retry on next launch
  }
}

/// Provides the app router key so message taps can navigate.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

/// Sets up all FCM listeners. Call this once after the router is ready.
void setupFcmListeners({
  required ApiClient apiClient,
  required GoRouter router,
}) {
  // 1. Foreground messages → local notification
  FirebaseMessaging.onMessage.listen((message) {
    showForegroundNotification(message);
  });

  // 2. Tapped from background/terminated → deep-link
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _navigateFromMessage(message, router);
  });

  // 3. Token refresh → re-register
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await apiClient.dio.post(
        '/notifications/device-token',
        data: {'fcmToken': newToken, 'platform': platform},
      );
    } catch (_) {}
  });
}

void _navigateFromMessage(RemoteMessage message, GoRouter router) {
  final data = message.data;
  final type = data['type'] as String?;
  final jobId = data['jobId'] as String?;

  switch (type) {
    case 'job_accepted':
    case 'job_en_route':
      if (jobId != null) router.push('/tracking/$jobId');
    case 'job_completed':
      if (jobId != null) router.push('/rating/$jobId');
    case 'payment_held':
      if (jobId != null) router.push('/payment/status/$jobId');
    default:
      router.push('/notifications');
  }
}
