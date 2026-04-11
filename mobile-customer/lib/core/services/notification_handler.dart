import 'package:go_router/go_router.dart';
import '../api/api_client.dart';

/// Handles a notification tap based on the [data] payload from FCM.
/// Call this from both [FirebaseMessaging.onMessageOpenedApp] and
/// [FirebaseMessaging.instance.getInitialMessage()].
void handleNotificationTap(
    Map<String, dynamic> data, GoRouter router) {
  final type = data['type'] as String?;

  if (type == 'MAINTENANCE_REMINDER') {
    final categoryId = data['categoryId'] as String?;
    final reminderId = data['reminderId'] as String?;

    // Best-effort mark as Booked — fire-and-forget
    if (reminderId != null) {
      _markReminderBooked(reminderId);
    }

    // Navigate to booking category (with or without pre-filled category)
    if (categoryId != null && categoryId.isNotEmpty) {
      router.go('/booking/category');
    } else {
      router.go('/booking/category');
    }
  }
  // All other types: no-op (handled by the existing _navigateFromMessage)
}

void _markReminderBooked(String reminderId) async {
  try {
    final api = ApiClient();
    try {
      await api.dio.patch(
        '/customers/me/reminders/$reminderId',
        data: {'action': 'Booked'},
      );
    } catch (_) {
      await api.dio.patch(
        '/customers/me/reminders/$reminderId',
        data: {'action': 'Dismiss'},
      );
    }
  } catch (_) {
    // Non-fatal, best-effort only
  }
}
