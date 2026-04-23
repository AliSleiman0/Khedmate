import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../providers/role_provider.dart';

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

String _deviceTokenPath(UserRole? role) => role == UserRole.provider
    ? '/providers/me/device-token'
    : '/customers/me/device-token';

Future<void> registerFcmToken(ApiClient apiClient, Ref ref) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    final role = ref.read(roleProvider);
    await apiClient.dio.post(
      _deviceTokenPath(role),
      data: {'fcmToken': token, 'platform': platform},
    );
  } catch (_) {
    // Non-fatal — will retry on next launch
  }
}

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

/// Wires FCM listeners. Notification-payload routing is intentionally minimal
/// at this phase — Phase 8 replaces `_navigateFromMessage` with a role-aware
/// notification handler.
void setupFcmListeners({
  required ApiClient apiClient,
  required GoRouter router,
  required Ref ref,
}) {
  FirebaseMessaging.onMessage.listen((message) {
    showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _navigateFromMessage(message, router);
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message == null) return;
    _navigateFromMessage(message, router);
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final role = ref.read(roleProvider);
      await apiClient.dio.post(
        _deviceTokenPath(role),
        data: {'fcmToken': newToken, 'platform': platform},
      );
    } catch (_) {}
  });
}

void _navigateFromMessage(RemoteMessage message, GoRouter router) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
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
  });
}
