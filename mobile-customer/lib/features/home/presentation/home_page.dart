import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../notifications/presentation/notifications_provider.dart';
import '../../rating/presentation/rating_bottom_sheet.dart';
import '../../rating/presentation/rating_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _categories = [
    ('تنظيف', Icons.cleaning_services),
    ('سباكة', Icons.plumbing),
    ('كهرباء', Icons.electric_bolt),
    ('نقل عفش', Icons.local_shipping),
    ('دهانات', Icons.format_paint),
    ('تكييف', Icons.ac_unit),
    ('نجارة', Icons.carpenter),
    ('أخرى', Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRatingsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('خدمتي'),
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
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending rating banner
          pendingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (pending) {
              if (pending.isEmpty) return const SizedBox.shrink();
              final first = pending.first;
              return _PendingRatingBanner(
                providerName: first.rateTarget,
                jobId: first.jobId,
                onRate: () async {
                  await RatingBottomSheet.show(
                    context,
                    jobId: first.jobId,
                    providerName: first.rateTarget,
                  );
                  ref.invalidate(pendingRatingsProvider);
                },
                onDismiss: () => ref.invalidate(pendingRatingsProvider),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ماذا تحتاج؟',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'اختر الخدمة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final (label, icon) = _categories[i];
                return InkWell(
                  onTap: () => context.go('/booking/category'),
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 44, color: AppColors.brandBlue),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.brandBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'السجل'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
        onTap: (i) {
          if (i == 1) context.go('/history');
          if (i == 2) context.go('/profile');
        },
      ),
    );
  }
}

class _PendingRatingBanner extends StatelessWidget {
  final String providerName;
  final String jobId;
  final VoidCallback onRate;
  final VoidCallback onDismiss;

  const _PendingRatingBanner({
    required this.providerName,
    required this.jobId,
    required this.onRate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.amber.withOpacity(0.15),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.amber, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'لديك تقييم معلق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRate,
              child: const Text(
                'قيّم الآن',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
