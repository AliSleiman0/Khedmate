import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/notification_model.dart';

class NotificationsPage {
  final List<NotificationModel> items;
  final int totalCount;

  const NotificationsPage({required this.items, required this.totalCount});
}

class NotificationsRepository {
  final ApiClient _client;

  NotificationsRepository(this._client);

  Future<NotificationsPage> getNotifications({int page = 1, int pageSize = 20}) async {
    final response = await _client.dio.get(
      '/notifications',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPage(
      items: items,
      totalCount: data['totalCount'] as int,
    );
  }

  Future<void> markRead(String notificationId) async {
    await _client.dio.post('/notifications/$notificationId/read');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ApiClient());
});
