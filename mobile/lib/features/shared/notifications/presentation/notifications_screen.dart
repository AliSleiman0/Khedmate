import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import '../domain/notification_model.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationsNotifierProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final notificationsAsync = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        title: Text(
          s.notifTitle,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(s.notifError,
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
        data: (items) => items.isEmpty
            ? _buildEmpty(s)
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsNotifierProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _NotificationCard(notification: items[index]),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty(S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            s.notifEmpty,
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
}

/// Role-aware notification tap routing. Kept in one place so FCM and the
/// in-app list produce the same destinations.
void handleNotificationTap(
  BuildContext context,
  WidgetRef ref,
  AppNotification n,
) {
  final role = ref.read(roleProvider) ?? UserRole.customer;
  final jobId = n.jobId;

  switch (n.type) {
    case 'JOB_ACCEPTED':
    case 'PROVIDER_EN_ROUTE':
    case 'PROVIDER_ARRIVED':
    case 'JOB_COMPLETED':
      if (jobId == null) return;
      if (role == UserRole.customer) {
        context.push('/customer/tracking/$jobId');
      } else {
        context.push('/provider/active-job/$jobId');
      }
      break;
    case 'NEW_JOB_AVAILABLE':
      if (role == UserRole.provider && jobId != null) {
        context.push('/provider/job-detail/$jobId');
      }
      break;
    case 'PAYMENT_HELD':
    case 'PAYMENT_RELEASED':
      if (jobId == null) return;
      if (role == UserRole.customer) {
        context.push('/customer/payment/status/$jobId');
      }
      break;
    case 'DISPUTE_OPENED':
    case 'DISPUTE_RESOLVED':
      if (jobId != null) {
        if (role == UserRole.customer) {
          context.push('/customer/history/$jobId');
        } else {
          context.push('/provider/active-job/$jobId');
        }
      }
      break;
    case 'MAINTENANCE_REMINDER':
      if (role == UserRole.customer) context.push('/customer/reminders');
      break;
    case 'VERIFICATION_APPROVED':
    case 'VERIFICATION_REJECTED':
      if (role == UserRole.provider) context.push('/provider/onboarding');
      break;
    case 'SUBSCRIPTION_ACTIVATED':
    case 'SUBSCRIPTION_CANCELLED':
    case 'SUBSCRIPTION_PAYMENT_FAILED':
      if (role == UserRole.provider) context.push('/provider/subscription');
      break;
    case 'NEW_CHAT_MESSAGE':
      if (jobId != null) {
        context.push(role == UserRole.provider
            ? '/provider/chat/$jobId'
            : '/customer/chat/$jobId');
      }
      break;
    default:
      // Unknown type — fall through and leave the screen as-is.
      break;
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return InkWell(
      onTap: () {
        ref
            .read(notificationsNotifierProvider.notifier)
            .markRead(notification.id);
        handleNotificationTap(context, ref, notification);
      },
      child: Container(
        color:
            notification.isRead ? null : AppColors.brandBlue.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10, top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.brandBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notification.createdAt, s),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt, S s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return s.timeNow;
    if (diff.inMinutes < 60) return s.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return s.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
