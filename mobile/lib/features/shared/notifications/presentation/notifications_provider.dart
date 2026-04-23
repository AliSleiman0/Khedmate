import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  int _totalCount = 0;

  int get totalCount => _totalCount;

  @override
  Future<List<AppNotification>> build() => _load();

  Future<List<AppNotification>> _load() async {
    final repo = ref.read(notificationRepositoryProvider);
    final page = await repo.getNotifications();
    _totalCount = page.totalCount;
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> markRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markRead(id);
    state = state.whenData((items) => [
          for (final n in items)
            if (n.id == id)
              AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                isRead: true,
                createdAt: n.createdAt,
                type: n.type,
                data: n.data,
              )
            else
              n
        ]);
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

/// Unread count for badge display.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsNotifierProvider);
  return notifs.valueOrNull?.where((n) => !n.isRead).length ?? 0;
});

/// Simple "has more" flag for future paginated UI.
final notificationsHasMoreProvider = Provider<bool>((ref) {
  final items = ref.watch(notificationsNotifierProvider).valueOrNull ?? const [];
  final total = ref.read(notificationsNotifierProvider.notifier).totalCount;
  return items.length < total;
});
