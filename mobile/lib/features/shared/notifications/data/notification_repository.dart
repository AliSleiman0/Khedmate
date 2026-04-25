import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../domain/notification_model.dart';

const _tag = 'NotifRepo';

class NotificationsPage {
  final List<AppNotification> items;
  final int totalCount;

  const NotificationsPage({required this.items, required this.totalCount});
}

class NotificationRepository {
  final ApiClient _client;
  final Ref _ref;

  NotificationRepository(this._client, this._ref);

  Future<NotificationsPage> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final role = _ref.read(roleProvider) ?? UserRole.customer;
    log.d(_tag, 'getNotifications start',
        data: {'role': role.name, 'page': page, 'pageSize': pageSize});
    final response = await _client.dio.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'role': role.name,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPage(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
    );
  }

  Future<void> markRead(String notificationId) async {
    log.d(_tag, 'markRead', data: {'id': notificationId});
    await _client.dio.post('/notifications/$notificationId/read');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider), ref);
});
