import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/job_repository.dart';
import '../../notifications/presentation/notifications_provider.dart';
import 'job_feed_provider.dart';
import 'active_jobs_screen.dart';
import 'completed_jobs_provider.dart';

const _categoryIcons = {
  'plumbing': Icons.plumbing,
  'electrical': Icons.electric_bolt,
  'cleaning': Icons.cleaning_services,
  'carpentry': Icons.carpenter,
  'painting': Icons.format_paint,
  'ac_maintenance': Icons.ac_unit,
};

class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final unreadCount = ref.watch(unreadCountProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.jobsTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.amber,
            tabs: [
              Tab(text: s.tabAvailable),
              Tab(text: s.tabActive),
              Tab(text: s.tabCompleted),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _AvailableJobsTab(),
            ActiveJobsScreen(),
            _CompletedJobsTab(),
          ],
        ),
      ),
    );
  }
}

class _AvailableJobsTab extends ConsumerWidget {
  const _AvailableJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(jobFeedNotifierProvider);

    return asyncJobs.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandBlue)),
      error: (e, _) => _ErrorState(
          onRefresh: () =>
              ref.read(jobFeedNotifierProvider.notifier).refresh()),
      data: (jobs) => RefreshIndicator(
        color: AppColors.brandBlue,
        onRefresh: () => ref.read(jobFeedNotifierProvider.notifier).refresh(),
        child: jobs.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: jobs.length,
                itemBuilder: (ctx, i) => _JobCard(job: jobs[i]),
              ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final JobSummary job;

  const _JobCard({required this.job});

  bool get _isNew => job.secondsRemaining > 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final icon = _categoryIcons[job.categoryId] ?? Icons.build;
    final minutesAgo =
        DateTime.now().difference(job.postedAt).inMinutes;
    final timeLabel =
        minutesAgo < 1 ? s.timeNow : s.timeMinutesAgo(minutesAgo);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.go('/job-detail/${job.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon with amber circle
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.amber.withOpacity(0.12),
                child: Icon(icon, color: AppColors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          job.categoryName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_isNew) ...[
                          const SizedBox(width: 8),
                          _PulsingDot(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.district,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        Text(
                          ' ${s.distanceKm(job.distanceKm)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.schedule_outlined,
                            size: 14, color: AppColors.textSecondary),
                        Text(
                          ' $timeLabel',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Countdown
              Column(
                children: [
                  Text(
                    '${job.secondsRemaining ~/ 60}:${(job.secondsRemaining % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: job.secondsRemaining < 30
                          ? AppColors.danger
                          : AppColors.brandBlue,
                    ),
                  ),
                  const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: AppColors.amber, shape: BoxShape.circle),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            s.jobsEmpty,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: () =>
                ref.read(jobFeedNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.brandBlue),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _ErrorState({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            s.jobsLoadError,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(s.retry, style: const TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CompletedJobsTab extends ConsumerWidget {
  const _CompletedJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final async = ref.watch(completedJobsProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandBlue)),
      error: (_, __) => Center(
          child: Text(s.tabCompletedError,
              style: const TextStyle(fontFamily: 'Cairo'))),
      data: (jobs) => jobs.isEmpty
          ? Center(
              child: Text(
                s.tabCompletedEmpty,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (ctx, i) {
                final job = jobs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.success.withOpacity(0.12),
                      child: const Icon(Icons.check_circle,
                          color: AppColors.success),
                    ),
                    title: Text(job.categoryName,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${job.district} · ${job.referenceNumber}',
                        style: const TextStyle(fontFamily: 'Cairo')),
                    trailing: Text(
                      'SAR ${job.netAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          color: AppColors.success),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
