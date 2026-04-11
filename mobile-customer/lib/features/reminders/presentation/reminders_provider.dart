import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../data/reminders_repository.dart';

// ---------------------------------------------------------------------------
// DI
// ---------------------------------------------------------------------------
final _remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(ApiClient());
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class RemindersNotifier extends AsyncNotifier<List<ReminderModel>> {
  @override
  Future<List<ReminderModel>> build() async {
    return ref.read(_remindersRepositoryProvider).fetchReminders();
  }

  Future<void> snooze(String id, int days, BuildContext context) async {
    if (days > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SNOOZE_DAYS_EXCEEDED',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }
    try {
      await ref.read(_remindersRepositoryProvider).snooze(id, days);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('REMINDER_NOT_FOUND') ||
          errStr.contains('REMINDER_ALREADY_DISMISSED') ||
          errStr.contains('SNOOZE_DAYS_EXCEEDED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errStr,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    }
  }

  Future<void> dismiss(String id) async {
    try {
      await ref.read(_remindersRepositoryProvider).dismiss(id);
    } catch (e) {
      final errStr = e.toString();
      // If already dismissed, silently succeed — item is gone
      if (errStr.contains('REMINDER_ALREADY_DISMISSED')) return;
    } finally {
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
    }
  }

  Future<void> markBooked(String id) async {
    try {
      await ref.read(_remindersRepositoryProvider).markBooked(id);
    } catch (_) {}
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((r) => r.id != id).toList());
  }
}

final remindersNotifierProvider =
    AsyncNotifierProvider<RemindersNotifier, List<ReminderModel>>(
        RemindersNotifier.new);
