import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../data/job_repository.dart';
import '../../notifications/presentation/notifications_provider.dart';
import 'job_feed_provider.dart';
import 'active_jobs_screen.dart';

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
    final unreadCount = ref.watch(unreadCountProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'الطلبات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
            tabs: const [
              Tab(text: 'المتاحة'),
              Tab(text: 'الجارية'),
              Tab(text: 'المنجزة'),
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: AppColors.brandBlue,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.work_outline), label: 'الطلبات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.attach_money), label: 'الأرباح'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'الملف الشخصي'),
          ],
          onTap: (i) {
            if (i == 1) context.go('/earnings');
            if (i == 2) context.go('/profile');
          },
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

class _JobCard extends StatelessWidget {
  final JobSummary job;

  const _JobCard({required this.job});

  bool get _isNew => job.secondsRemaining > 100;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[job.categoryId] ?? Icons.build;
    final minutesAgo =
        DateTime.now().difference(job.postedAt).inMinutes;
    final timeLabel =
        minutesAgo < 1 ? 'الآن' : 'منذ $minutesAgo دقيقة';

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
                          ' ${job.distanceKm} كم',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات متاحة حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.refresh, color: AppColors.brandBlue),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _ErrorState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'تعذر تحميل الطلبات',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CompletedJobsTab extends StatelessWidget {
  const _CompletedJobsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد طلبات منجزة',
        style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
      ),
    );
  }
}
