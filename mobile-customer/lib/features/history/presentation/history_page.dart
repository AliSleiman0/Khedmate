import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/colors.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
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
    final categoryMap = {
      'plumbing': 'سباكة',
      'electrical': 'كهرباء',
      'cleaning': 'تنظيف',
      'carpentry': 'نجارة',
      'painting': 'دهان',
      'ac_maintenance': 'تكييف',
    };
    final categoryId = json['categoryId'] as String? ?? '';
    return _JobHistoryItem(
      id: (json['jobId'] ?? json['id'] ?? '').toString(),
      referenceNumber: json['referenceNumber'] as String? ?? '',
      categoryName: categoryMap[categoryId] ?? categoryId,
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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final _historyProvider = FutureProvider<List<_JobHistoryItem>>((ref) async {
  final client = ApiClient();
  final response = await client.dio.get('/bookings/jobs');
  final data = response.data as Map<String, dynamic>;
  final items = data['data'] as List? ?? [];
  return items
      .map((e) => _JobHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(_historyProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الطلبات',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
        ),
        body: asyncHistory.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => const Center(
            child: Text('تعذر تحميل السجل',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
          data: (jobs) => jobs.isEmpty
              ? const Center(
                  child: Text('لا توجد طلبات سابقة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
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

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------
const _statusLabels = {
  'Pending':    'معلّق',
  'Accepted':   'مقبول',
  'EnRoute':    'في الطريق',
  'InProgress': 'جاري التنفيذ',
  'Completed':  'مكتمل',
  'Paid':       'مدفوع',
  'Expired':    'منتهي',
};

const _statusColors = {
  'Pending':    AppColors.amber,
  'Accepted':   AppColors.brandBlue,
  'EnRoute':    AppColors.amber,
  'InProgress': AppColors.amber,
  'Completed':  AppColors.success,
  'Paid':       AppColors.brandBlue,
  'Expired':    AppColors.danger,
};

class _HistoryCard extends StatelessWidget {
  final _JobHistoryItem job;

  const _HistoryCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabels[job.status] ?? job.status;
    final color = _statusColors[job.status] ?? AppColors.textSecondary;
    final isCompleted =
        job.status == 'Completed' || job.status == 'Paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/history/${job.id}'),
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
                    Text(job.categoryName,
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تفاصيل الطلب',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'رقم الطلب', value: job.referenceNumber),
                  _DetailRow(label: 'الخدمة', value: job.categoryName),
                  _DetailRow(
                    label: 'التاريخ',
                    value:
                        '${job.createdAt.year}-${job.createdAt.month.toString().padLeft(2, '0')}-${job.createdAt.day.toString().padLeft(2, '0')}',
                  ),
                  if (job.address.isNotEmpty)
                    _DetailRow(label: 'العنوان', value: job.address),
                  if (job.providerName != null && job.providerName!.isNotEmpty)
                    _DetailRow(label: 'المزود', value: job.providerName!),
                  const SizedBox(height: 16),

                  // Before photos
                  if (job.beforePhotoUrls.isNotEmpty) ...[
                    const Text(
                      'صور قبل العمل',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _PhotoRow(urls: job.beforePhotoUrls),
                    const SizedBox(height: 16),
                  ],

                  // After photos (only when completed/paid)
                  if (job.afterPhotoUrls.isNotEmpty &&
                      (job.status == 'Completed' || job.status == 'Paid')) ...[
                    const Text(
                      'صور بعد العمل',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _PhotoRow(urls: job.afterPhotoUrls),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final List<String> urls;

  const _PhotoRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '${AppConfig.backendHost}${urls[i]}',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.surface,
                child:
                    const Icon(Icons.image, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
