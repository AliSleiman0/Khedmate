import '../../../core/api/api_client.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class ReminderModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final DateTime scheduledFor;
  final String status; // Scheduled | Sent | Snoozed | Overdue (derived)

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

    // Client-side Overdue derivation: if backend says Sent and date has passed
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

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------
class RemindersRepository {
  final ApiClient _api;

  RemindersRepository(this._api);

  Future<List<ReminderModel>> fetchReminders() async {
    final response = await _api.dio.get('/customers/me/reminders');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List? ?? [];
    return items
        .map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> snooze(String id, int days) async {
    await _api.dio.patch(
      '/customers/me/reminders/$id',
      data: {'action': 'Snooze', 'snoozeDays': days},
    );
  }

  Future<void> dismiss(String id) async {
    await _api.dio.patch(
      '/customers/me/reminders/$id',
      data: {'action': 'Dismiss'},
    );
  }

  Future<void> markBooked(String id) async {
    try {
      await _api.dio.patch(
        '/customers/me/reminders/$id',
        data: {'action': 'Booked'},
      );
    } catch (_) {
      // Fallback to Dismiss if Booked action is not supported
      await _api.dio.patch(
        '/customers/me/reminders/$id',
        data: {'action': 'Dismiss'},
      );
    }
  }
}
