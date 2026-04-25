import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../data/reminders_repository.dart';

const _tag = 'RemindersNotifier';

final _remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.read(apiClientProvider));
});

class RemindersNotifier extends AsyncNotifier<List<ReminderModel>> {
  @override
  Future<List<ReminderModel>> build() async {
    log.d(_tag, 'load start');
    try {
      final list =
          await ref.read(_remindersRepositoryProvider).fetchReminders();
      log.i(_tag, 'load ok', data: {'count': list.length});
      return list;
    } catch (e) {
      log.e(_tag, 'load failed', error: e);
      rethrow;
    }
  }

  Future<void> snooze(String id, int days, BuildContext context) async {
    if (days > 30) {
      log.w(_tag, 'snooze blocked',
          data: {'reason': 'SNOOZE_DAYS_EXCEEDED', 'days': days});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SNOOZE_DAYS_EXCEEDED',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }
    log.d(_tag, 'snooze start', data: {'id': id, 'days': days});
    try {
      await ref.read(_remindersRepositoryProvider).snooze(id, days);
      log.i(_tag, 'snooze ok', data: {'id': id, 'days': days});
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
    } catch (e) {
      final errStr = e.toString();
      log.w(_tag, 'snooze failed', error: e, data: {'id': id});
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
    log.d(_tag, 'dismiss start', data: {'id': id});
    try {
      await ref.read(_remindersRepositoryProvider).dismiss(id);
      log.i(_tag, 'dismiss ok', data: {'id': id});
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('REMINDER_ALREADY_DISMISSED')) {
        log.w(_tag, 'dismiss already dismissed', data: {'id': id});
        return;
      }
      log.w(_tag, 'dismiss failed', error: e, data: {'id': id});
    } finally {
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((r) => r.id != id).toList());
    }
  }

  Future<void> markBooked(String id) async {
    log.i(_tag, 'deep link to booking', data: {'id': id});
    try {
      await ref.read(_remindersRepositoryProvider).markBooked(id);
    } catch (e) {
      log.w(_tag, 'markBooked failed', error: e, data: {'id': id});
    }
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((r) => r.id != id).toList());
  }
}

final remindersNotifierProvider =
    AsyncNotifierProvider<RemindersNotifier, List<ReminderModel>>(
        RemindersNotifier.new);
