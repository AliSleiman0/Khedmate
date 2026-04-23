import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';

class _JobHistoryItem {
  final String id;
  final String referenceNumber;
  final String categoryName;
  final String status;
  final String address;
  final DateTime createdAt;
  final String? providerName;
  final List<String> beforePhotoUrls;
  final List<String> afterPhotoUrls;

  const _JobHistoryItem({
    required this.id,
    required this.referenceNumber,
    required this.categoryName,
    required this.status,
    required this.address,
    required this.createdAt,
    this.providerName,
    this.beforePhotoUrls = const [],
    this.afterPhotoUrls = const [],
  });

  factory _JobHistoryItem.fromJson(Map<String, dynamic> json) {
    final categoryId = json['categoryId'] as String? ?? '';
    return _JobHistoryItem(
      id: (json['jobId'] ?? json['id'] ?? '').toString(),
      referenceNumber: json['referenceNumber'] as String? ?? '',
      categoryName: categoryId,
      status: json['status'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      providerName: json['providerName'] as String?,
      beforePhotoUrls: (json['beforePhotoUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      afterPhotoUrls: (json['afterPhotoUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

final _historyProvider = FutureProvider<List<_JobHistoryItem>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('/bookings/jobs');
  final data = response.data as Map<String, dynamic>;
  final items = data['data'] as List? ?? [];
  return items
      .map((e) => _JobHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final asyncHistory = ref.watch(_historyProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.historyTitle,
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
        ),
        body: asyncHistory.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => Center(
            child: Text(s.historyLoadError,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
          data: (jobs) => jobs.isEmpty
              ? Center(
                  child: Text(s.historyEmpty,
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontSize: 16)),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(_historyProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    itemBuilder: (ctx, i) => _HistoryCard(job: jobs[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

const _statusColors = {
  'Pending':    AppColors.amber,
  'Accepted':   AppColors.brandBlue,
  'EnRoute':    AppColors.amber,
  'InProgress': AppColors.amber,
  'Completed':  AppColors.success,
  'Paid':       AppColors.brandBlue,
  'Expired':    AppColors.danger,
};

class _HistoryCard extends ConsumerWidget {
  final _JobHistoryItem job;

  const _HistoryCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final categoryNames = {
      'plumbing':       s.catPlumbing,
      'electrical':     s.catElectrical,
      'cleaning':       s.catCleaning,
      'carpentry':      s.catCarpentry,
      'painting':       s.catPainting,
      'ac_maintenance': s.catAC,
      'moving':         s.catMoving,
      'other':          s.catOther,
    };
    final statusLabels = {
      'Pending':    s.statusPending,
      'Accepted':   s.statusAccepted,
      'EnRoute':    s.statusEnRoute,
      'InProgress': s.statusInProgress,
      'Completed':  s.statusCompleted,
      'Paid':       s.statusPaid,
      'Expired':    s.statusExpired,
    };
    final displayName = categoryNames[job.categoryName] ??
        job.categoryName.replaceAll('_', ' ');
    final label = statusLabels[job.status] ?? job.status;
    final color = _statusColors[job.status] ?? AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/customer/history/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandBlue.withOpacity(0.1),
                child: const Icon(Icons.home_repair_service,
                    color: AppColors.brandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold)),
                    Text(job.referenceNumber,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    Text(
                      '${job.createdAt.year}-${job.createdAt.month.toString().padLeft(2, '0')}-${job.createdAt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
                backgroundColor: color,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

