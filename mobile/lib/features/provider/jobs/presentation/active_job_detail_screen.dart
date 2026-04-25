import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../shared/chat/presentation/chat_provider.dart';
import 'active_job_provider.dart';

const _tag = 'ActiveJobDetail';

class ActiveJobDetailScreen extends ConsumerWidget {
  final String jobId;

  const ActiveJobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJob = ref.watch(activeJobNotifierProvider(jobId));
    final job = asyncJob.valueOrNull;
    final chatStatuses = {'Accepted', 'EnRoute', 'InProgress'};
    final showChat = job != null && chatStatuses.contains(job.status);

    Widget? chatFab;
    if (showChat) {
      final unreadAsync = ref.watch(unreadCountProvider(jobId));
      final unreadCount = unreadAsync.valueOrNull ?? 0;
      chatFab = FloatingActionButton(
        backgroundColor: AppColors.brandBlue,
        onPressed: () {
          log.d(_tag, 'chat fab tap', data: {'jobId': jobId});
          context.push(
            '/provider/chat/$jobId?name=${Uri.encodeComponent(job.customerFirstName ?? '')}',
          );
        },
        child: Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble, color: Colors.white),
            if (unreadCount > 0)
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      // Phase 07 lock — providers must not lose context mid-job. The
      // app-wide back-button sweep deliberately skips this screen; do not
      // add an AppBackButton or BackChip here without a follow-up product
      // discussion about how status / GPS broadcast should behave on exit.
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          floatingActionButton: chatFab,
          body: asyncJob.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandBlue)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Builder(
                  builder: (context) {
                    final s = S.of(ref);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(s.jobLoadError,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(activeJobNotifierProvider(jobId)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandBlue),
                          child: Text(s.retry,
                              style: const TextStyle(
                                  fontFamily: 'Cairo', color: Colors.white)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            data: (job) => _JobBody(job: job, jobId: jobId),
          ),
        ),
      ),
    );
  }
}

class _JobBody extends ConsumerWidget {
  final dynamic job;
  final String jobId;

  const _JobBody({required this.job, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
          _Header(job: job),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RefBadge(referenceNumber: job.referenceNumber),
                  const SizedBox(height: 16),
                  _InfoCard(job: job),
                  const SizedBox(height: 24),
                  _StatusContent(job: job, jobId: jobId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final dynamic job;

  const _Header({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final statusLabel = switch (job.status) {
      'Accepted' => s.statusAccepted,
      'EnRoute' => s.statusEnRoute,
      'InProgress' => s.providerStatusInProgress,
      'Completed' => s.statusCompleted,
      _ => job.status as String,
    };
    final statusColor = _statusColor(job.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.15)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              job.categoryName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'Accepted' => AppColors.brandBlue,
        'EnRoute' => AppColors.amber,
        'InProgress' => AppColors.amber,
        'Completed' => Colors.green,
        _ => AppColors.brandBlue,
      };
}

class _RefBadge extends ConsumerWidget {
  final String referenceNumber;

  const _RefBadge({required this.referenceNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${s.jobRefNo}: ',
              style: const TextStyle(
                  fontFamily: 'Cairo', color: AppColors.textSecondary)),
          Text(referenceNumber,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
                letterSpacing: 1.2,
              )),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  final dynamic job;

  const _InfoCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
                icon: Icons.home_repair_service,
                label: s.jobServiceLabel,
                value: job.categoryName),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.location_on,
                label: s.jobLocation,
                value: job.district),
            if (job.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                  icon: Icons.description,
                  label: s.jobDescLabel,
                  value: job.description),
            ],
            if (job.customerFirstName != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                  icon: Icons.person,
                  label: s.jobCustomerLabel,
                  value: job.customerFirstName!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.brandBlue),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
        ),
      ],
    );
  }
}

class _StatusContent extends ConsumerWidget {
  final dynamic job;
  final String jobId;

  const _StatusContent({required this.job, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (job.status) {
      'Accepted' => _AcceptedActions(jobId: jobId),
      'EnRoute' => _EnRouteActions(jobId: jobId, job: job),
      'InProgress' => _InProgressActions(jobId: jobId),
      'Completed' => const _CompletedView(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _AcceptedActions extends ConsumerWidget {
  final String jobId;

  const _AcceptedActions({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(activeJobNotifierProvider(jobId)).isLoading;

    final s = S.of(ref);
    return _PrimaryButton(
      label: s.statusEnRoute,
      icon: Icons.directions_car,
      color: AppColors.brandBlue,
      isLoading: isLoading,
      onPressed: () {
        log.d(_tag, 'action tap',
            data: {'jobId': jobId, 'action': 'enroute'});
        ref.read(activeJobNotifierProvider(jobId).notifier).advanceStatus();
      },
    );
  }
}

class _EnRouteActions extends ConsumerWidget {
  final String jobId;
  final dynamic job;

  const _EnRouteActions({required this.jobId, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final isLoading = ref.watch(activeJobNotifierProvider(jobId)).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job.customerPhone != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.phone, color: AppColors.brandBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  _maskPhone(job.customerPhone!),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
              ],
            ),
          ),
        _PrimaryButton(
          label: s.jobArriveStart,
          icon: Icons.play_circle_outline,
          color: AppColors.brandBlue,
          isLoading: isLoading,
          onPressed: () {
            log.d(_tag, 'action tap',
                data: {'jobId': jobId, 'action': 'arrived_or_start'});
            ref
                .read(activeJobNotifierProvider(jobId).notifier)
                .advanceStatus();
          },
        ),
      ],
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
  }
}

class _InProgressActions extends ConsumerWidget {
  final String jobId;

  const _InProgressActions({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return _PrimaryButton(
      label: s.jobFinish,
      icon: Icons.check_circle_outline,
      color: Colors.green,
      isLoading: false,
      onPressed: () => _navigateToUploadPhotos(context, ref),
    );
  }

  Future<void> _navigateToUploadPhotos(
      BuildContext context, WidgetRef ref) async {
    log.d(_tag, 'action tap',
        data: {'jobId': jobId, 'action': 'finish_upload'});
    await context.push('/provider/active-job/$jobId/after-photos');
    if (context.mounted) {
      ref.invalidate(activeJobNotifierProvider(jobId));
    }
  }
}

class _CompletedView extends ConsumerWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.jobCompletedAwaitPay,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
