import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../logging/app_logger.dart';
import '../providers/role_provider.dart';
import 'notification_handler.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Initialise [FlutterLocalNotificationsPlugin] — call once during app boot.
Future<void> initLocalNotifications() async {
  try {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    log.i('Fcm', 'local notif init ok');
  } catch (e, st) {
    log.e('Fcm', 'local notif init failed', error: e, stack: st);
    rethrow;
  }
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

Future<void> registerFcmToken(
  ApiClient apiClient,
  ProviderContainer container,
) async {
  final role = container.read(roleProvider);
  log.i('Fcm', 'token register start', data: {'role': role?.name});
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      log.w('Fcm', 'fcm token unavailable');
      return;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    await apiClient.dio.post(
      _deviceTokenPath(role),
      data: {'fcmToken': token, 'platform': platform},
    );
    log.i('Fcm', 'token register ok', data: {'platform': platform});
  } catch (e, st) {
    // Non-fatal — will retry on next launch.
    log.e('Fcm', 'token register failed', error: e, stack: st);
  }
}

/// Wires FCM listeners. All tap-driven routing is delegated to the shared
/// [NotificationHandler] so FCM, in-app notifications, and deep links all
/// converge on a single role-aware dispatcher.
void setupFcmListeners({
  required ApiClient apiClient,
  required NotificationHandler handler,
  required ProviderContainer container,
}) {
  FirebaseMessaging.onMessage.listen((message) {
    log.d('Fcm', 'fg msg', data: {
      'type': message.data['type'],
      'jobId': message.data['jobId'],
    });
    showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    log.i('Fcm', 'tap opened app', data: {'type': message.data['type']});
    handler.handleFcmTap(message);
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message == null) return;
    log.i('Fcm', 'tap cold start', data: {'type': message.data['type']});
    handler.handleFcmTap(message);
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    log.i('Fcm', 'token rotated, re-registering');
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final role = container.read(roleProvider);
      await apiClient.dio.post(
        _deviceTokenPath(role),
        data: {'fcmToken': newToken, 'platform': platform},
      );
      log.i('Fcm', 'token rotation re-registered ok');
    } catch (e, st) {
      log.e('Fcm', 'token rotation re-register failed',
          error: e, stack: st);
    }
  });

  log.i('Fcm', 'listeners wired');
}
