import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/reminders_repository.dart';
import 'reminders_provider.dart';
import '../../booking/presentation/booking_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  static const _categoryIds = [
    'cleaning', 'plumbing', 'electrical', 'moving',
    'painting', 'ac_maintenance', 'carpentry', 'other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final remindersAsync = ref.watch(remindersNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.remindersTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: remindersAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.errorGeneric,
                    style: const TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(remindersNotifierProvider),
                  child: Text(s.retry,
                      style: const TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
          data: (reminders) {
            if (reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.build_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      s.remindersEmpty,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (ctx, i) => _ReminderCard(reminder: reminders[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final ReminderModel reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final categoryNames = {
      'cleaning':       s.catCleaning,
      'plumbing':       s.catPlumbing,
      'electrical':     s.catElectrical,
      'moving':         s.catMoving,
      'painting':       s.catPainting,
      'ac_maintenance': s.catAC,
      'carpentry':      s.catCarpentry,
      'other':          s.catOther,
    };

    final categoryDisplay =
        categoryNames[reminder.categoryId] ??
        reminder.categoryName.isNotEmpty
            ? reminder.categoryName
            : reminder.categoryId.replaceAll('_', ' ');

    final formattedDate =
        DateFormat('d MMMM', 'ar').format(reminder.scheduledFor);
    final isOverdue = reminder.status == 'Overdue';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: AppColors.brandBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryDisplay,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Text(
                      s.remindersOverdue,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'snooze7') {
                      await ref
                          .read(remindersNotifierProvider.notifier)
                          .snooze(reminder.id, 7, context);
                    } else if (value == 'snooze30') {
                      await ref
                          .read(remindersNotifierProvider.notifier)
                          .snooze(reminder.id, 30, context);
                    } else if (value == 'dismiss') {
                      await ref
                          .read(remindersNotifierProvider.notifier)
                          .dismiss(reminder.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'snooze7',
                      child: Text(s.remindersSnooze7,
                          style: const TextStyle(fontFamily: 'Cairo')),
                    ),
                    PopupMenuItem(
                      value: 'snooze30',
                      child: Text(s.remindersSnooze30,
                          style: const TextStyle(fontFamily: 'Cairo')),
                    ),
                    PopupMenuItem(
                      value: 'dismiss',
                      child: Text(s.remindersDismiss,
                          style: const TextStyle(
                              fontFamily: 'Cairo', color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.remindersDue(formattedDate),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Mark as booked (fire-and-forget)
                  ref
                      .read(remindersNotifierProvider.notifier)
                      .markBooked(reminder.id);

                  // Pre-select category then navigate
                  final categoryNames = {
                    'cleaning':       s.catCleaning,
                    'plumbing':       s.catPlumbing,
                    'electrical':     s.catElectrical,
                    'moving':         s.catMoving,
                    'painting':       s.catPainting,
                    'ac_maintenance': s.catAC,
                    'carpentry':      s.catCarpentry,
                    'other':          s.catOther,
                  };
                  final catLabel =
                      categoryNames[reminder.categoryId] ?? reminder.categoryId;
                  ref
                      .read(bookingNotifierProvider.notifier)
                      .setCategory(reminder.categoryId, catLabel);
                  if (context.mounted) {
                    context.go('/booking/description');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  s.remindersBookNow,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
