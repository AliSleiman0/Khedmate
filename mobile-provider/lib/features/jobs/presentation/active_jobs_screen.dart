import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/signalr_service.dart';
import '../../rating/presentation/provider_rating_bottom_sheet.dart';
import '../../rating/presentation/provider_rating_provider.dart';
import '../data/job_repository.dart';

// ---------------------------------------------------------------------------
// Provider — stream-updated list of active jobs
// ---------------------------------------------------------------------------
final activeJobsStreamProvider =
    StateNotifierProvider<_ActiveJobsNotifier, AsyncValue<List<JobDetail>>>(
  (ref) => _ActiveJobsNotifier(ref),
);

class _ActiveJobsNotifier extends StateNotifier<AsyncValue<List<JobDetail>>> {
  final Ref _ref;

  _ActiveJobsNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
    _subscribeSignalR();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final jobs = await _ref.read(jobRepositoryProvider).getActiveJobs();
      state = AsyncData(jobs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _subscribeSignalR() {
    _ref.read(signalRServiceProvider).on('JobStatusChanged', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      final jobId = data['jobId'].toString();
      final newStatus = data['status'] as String? ?? '';

      final current = state.valueOrNull;
      if (current == null) return;

      // If job moved to Completed, keep it in the list so provider sees the status
      state = AsyncData(current
          .map((j) => j.id == jobId ? j.copyWith(status: newStatus) : j)
          .toList());
    });
  }

  Future<void> refresh() => _load();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ActiveJobsScreen extends ConsumerWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(activeJobsStreamProvider);
    final pendingJobIds = ref.watch(pendingRatingJobIdsProvider).valueOrNull ?? {};

    final s = S.of(ref);
    return asyncJobs.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.jobsActiveLoadError,
                style: const TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(activeJobsStreamProvider.notifier).refresh(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.brandBlue),
              child: Text(s.retry,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
      data: (jobs) => jobs.isEmpty
          ? Center(
              child: Text(
                s.jobsActiveEmpty,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(activeJobsStreamProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: jobs.length,
                itemBuilder: (ctx, i) => _ActiveJobCard(
                  job: jobs[i],
                  needsRating: pendingJobIds.contains(jobs[i].id),
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card — tappable, live status chip
// ---------------------------------------------------------------------------
const _statusColors = {
  'Accepted':   AppColors.brandBlue,
  'EnRoute':    AppColors.amber,
  'InProgress': AppColors.amber,
  'Completed':  Colors.green,
  'Paid':       Colors.teal,
};

class _ActiveJobCard extends ConsumerWidget {
  final JobDetail job;
  final bool needsRating;

  const _ActiveJobCard({required this.job, this.needsRating = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final statusLabels = {
      'Accepted':   s.statusAccepted,
      'EnRoute':    s.statusEnRoute,
      'InProgress': s.statusInProgress,
      'Completed':  s.statusCompleted,
      'Paid':       s.statusPaid,
    };
    final statusLabel = statusLabels[job.status] ?? job.status;
    final statusColor = _statusColors[job.status] ?? AppColors.brandBlue;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/active-job/${job.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.categoryName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Chip(
                      label: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: statusColor,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.district,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.referenceNumber,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (needsRating) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ProviderRatingBottomSheet.show(
                      context,
                      jobId: job.id,
                      customerName: job.customerFirstName ?? s.chatCustomer,
                    ).then((_) => ref.invalidate(pendingRatingJobIdsProvider)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_outline_rounded,
                              size: 14, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text(
                            s.rateCustomer,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
