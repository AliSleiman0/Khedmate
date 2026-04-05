import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_repository.dart';
import '../domain/notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() => _load();

  Future<List<NotificationModel>> _load() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final page = await repo.getNotifications();
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> markRead(String id) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markRead(id);
    state = state.whenData((items) => [
          for (final n in items)
            if (n.id == id)
              NotificationModel(
                id: n.id,
                title: n.title,
                body: n.body,
                isRead: true,
                createdAt: n.createdAt,
              )
            else
              n
        ]);
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        NotificationsNotifier.new);

/// Unread count for badge display.
final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsNotifierProvider);
  return notifs.valueOrNull?.where((n) => !n.isRead).length ?? 0;
});
