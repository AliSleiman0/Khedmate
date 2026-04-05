import 'dart:io';
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

Future<void> registerFcmToken(ApiClient apiClient) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    await apiClient.dio.post(
      '/notifications/device-token',
      data: {'fcmToken': token, 'platform': platform},
    );
  } catch (_) {}
}

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

void setupFcmListeners({
  required ApiClient apiClient,
  required GoRouter router,
}) {
  FirebaseMessaging.onMessage.listen((message) {
    showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _navigateFromMessage(message, router);
  });

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
    case 'payment_released':
      router.push('/payout-status');
    case 'new_job':
      router.push('/jobs');
    case 'verification_approved':
    case 'verification_rejected':
      router.push('/onboarding');
    default:
      router.push('/notifications');
  }
}
