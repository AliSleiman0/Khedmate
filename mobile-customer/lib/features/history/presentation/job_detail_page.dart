import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../booking/presentation/booking_provider.dart';
import '../../../core/constants/colors.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _JobDetail {
  final String id;
  final String referenceNumber;
  final String categoryId;
  final String status;
  final String address;
  final String description;
  final DateTime createdAt;
  final String? providerName;
  final List<String> beforePhotoUrls;
  final List<String> afterPhotoUrls;
  final bool hasOpenDispute;
  final String? transactionStatus;

  const _JobDetail({
    required this.id,
    required this.referenceNumber,
    required this.categoryId,
    required this.status,
    required this.address,
    required this.description,
    required this.createdAt,
    this.providerName,
    this.beforePhotoUrls = const [],
    this.afterPhotoUrls = const [],
    this.hasOpenDispute = false,
    this.transactionStatus,
  });

  factory _JobDetail.fromJson(Map<String, dynamic> json) {
    return _JobDetail(
      id: (json['jobId'] ?? json['id'] ?? '').toString(),
      referenceNumber: json['referenceNumber'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      hasOpenDispute: json['hasOpenDispute'] as bool? ?? false,
      transactionStatus: json['transactionStatus'] as String?,
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

  bool get canRaiseDispute =>
      status == 'Paid' && transactionStatus == 'Held' && !hasOpenDispute;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final jobDetailProvider =
    FutureProvider.autoDispose.family<_JobDetail, String>((ref, jobId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('/bookings/jobs/$jobId');
  final data = (response.data as Map<String, dynamic>)['data']
      as Map<String, dynamic>;
  return _JobDetail.fromJson(data);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class JobDetailPage extends ConsumerWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  static const Map<String, String> _categoryNames = {
    'plumbing': 'سباكة',
    'electrical': 'كهرباء',
    'cleaning': 'تنظيف',
    'carpentry': 'نجارة',
    'painting': 'دهان',
    'ac_maintenance': 'تكييف',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(jobDetailProvider(jobId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: asyncDetail.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تعذر تحميل تفاصيل الطلب',
                    style: TextStyle(fontFamily: 'Cairo')),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(jobDetailProvider(jobId)),
                  child: const Text('إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
          data: (job) => _JobDetailBody(
            job: job,
            categoryNames: _categoryNames,
            onDisputeRaised: () => ref.invalidate(jobDetailProvider(jobId)),
          ),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _JobDetailBody extends StatelessWidget {
  final _JobDetail job;
  final Map<String, String> categoryNames;
  final VoidCallback onDisputeRaised;

  const _JobDetailBody({
    required this.job,
    required this.categoryNames,
    required this.onDisputeRaised,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.referenceNumber,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    _StatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                    label: 'الفئة',
                    value: categoryNames[job.categoryId] ?? job.categoryId),
                _InfoRow(label: 'العنوان', value: job.address),
                _InfoRow(label: 'الوصف', value: job.description),
                _InfoRow(
                    label: 'تاريخ الطلب',
                    value: _formatDate(job.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dispute status chip (if open dispute exists)
          if (job.hasOpenDispute)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.gavel_rounded, color: AppColors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'الشكوى قيد المراجعة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Before photos section
          if (job.beforePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(title: 'صور قبل الخدمة'),
            const SizedBox(height: 8),
            _PhotoGrid(urls: job.beforePhotoUrls),
          ],

          // After photos section
          if (job.afterPhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(title: 'صور بعد الخدمة'),
            const SizedBox(height: 8),
            _PhotoGrid(urls: job.afterPhotoUrls),
          ],

          const SizedBox(height: 24),

          // Raise dispute button (only when eligible)
          if (job.canRaiseDispute)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.push(
                    '/dispute/raise',
                    extra: {
                      'jobId': job.id,
                      'referenceNumber': job.referenceNumber,
                    },
                  );
                  onDisputeRaised();
                },
                icon: const Icon(Icons.report_problem_outlined,
                    color: AppColors.amber),
                label: const Text(
                  'رفع شكوى',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.amber, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PhotoGrid extends StatelessWidget {
  final List<String> urls;
  const _PhotoGrid({required this.urls});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: urls
            .map((url) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
                  ),
                ))
            .toList(),
      );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  static const Map<String, Map<String, dynamic>> _styles = {
    'Pending':    {'label': 'قيد الانتظار', 'bg': Color(0xFFFFF3CD), 'fg': Color(0xFF856404)},
    'Accepted':   {'label': 'مقبول',        'bg': Color(0xFFD1ECF1), 'fg': Color(0xFF0C5460)},
    'EnRoute':    {'label': 'في الطريق',    'bg': Color(0xFFCCE5FF), 'fg': Color(0xFF004085)},
    'InProgress': {'label': 'جاري التنفيذ','bg': Color(0xFFD4EDDA), 'fg': Color(0xFF155724)},
    'Completed':  {'label': 'مكتمل',        'bg': Color(0xFFD4EDDA), 'fg': Color(0xFF155724)},
    'Paid':       {'label': 'مدفوع',        'bg': Color(0xFFD1C4E9), 'fg': Color(0xFF4527A0)},
    'Expired':    {'label': 'منتهي',        'bg': Color(0xFFF8D7DA), 'fg': Color(0xFF721C24)},
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[status] ?? _styles['Pending']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        style['label'] as String,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: style['fg'] as Color,
        ),
      ),
    );
  }
}
