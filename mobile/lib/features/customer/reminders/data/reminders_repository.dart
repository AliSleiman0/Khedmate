import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';

const _tag = 'RemindersRepo';

class ReminderModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final DateTime scheduledFor;
  final String status;

  const ReminderModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.scheduledFor,
    required this.status,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'Scheduled';
    final scheduledFor = json['scheduledFor'] != null
        ? DateTime.parse(json['scheduledFor'] as String)
        : DateTime.now();

    final derivedStatus =
        (rawStatus == 'Sent' && scheduledFor.isBefore(DateTime.now()))
            ? 'Overdue'
            : rawStatus;

    return ReminderModel(
      id: (json['id'] ?? '').toString(),
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      scheduledFor: scheduledFor,
      status: derivedStatus,
    );
  }
}

class RemindersRepository {
  final ApiClient _api;

  RemindersRepository(this._api);

  Future<List<ReminderModel>> fetchReminders() async {
    log.d(_tag, 'fetchReminders start');
    final response = await _api.dio.get('/customers/me/reminders');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List? ?? [];
    return items
        .map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> snooze(String id, int days) async {
    log.d(_tag, 'snooze start', data: {'id': id, 'days': days});
    await _api.dio.patch(
      '/customers/me/reminders/$id',
      data: {'action': 'Snooze', 'snoozeDays': days},
    );
  }

  Future<void> dismiss(String id) async {
    log.d(_tag, 'dismiss start', data: {'id': id});
    await _api.dio.patch(
      '/customers/me/reminders/$id',
      data: {'action': 'Dismiss'},
    );
  }

  Future<void> markBooked(String id) async {
    log.d(_tag, 'markBooked start', data: {'id': id});
    try {
      await _api.dio.patch(
        '/customers/me/reminders/$id',
        data: {'action': 'Booked'},
      );
    } catch (e) {
      log.w(_tag, 'markBooked fallback to dismiss',
          error: e, data: {'id': id});
      await _api.dio.patch(
        '/customers/me/reminders/$id',
        data: {'action': 'Dismiss'},
      );
    }
  }
}
