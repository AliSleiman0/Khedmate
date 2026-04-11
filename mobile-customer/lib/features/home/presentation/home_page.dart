import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../notifications/presentation/notifications_provider.dart';
import '../../rating/presentation/rating_bottom_sheet.dart';
import '../../rating/presentation/rating_provider.dart';
import '../../booking/presentation/booking_provider.dart';

/// Holds the home search query string.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Category IDs matching the backend enum order.
const _categoryIds = [
  'cleaning', 'plumbing', 'electrical', 'moving',
  'painting', 'ac_maintenance', 'carpentry', 'other',
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final allCategories = [
      (s.catCleaning,   Icons.cleaning_services),
      (s.catPlumbing,   Icons.plumbing),
      (s.catElectrical, Icons.electric_bolt),
      (s.catMoving,     Icons.local_shipping),
      (s.catPainting,   Icons.format_paint),
      (s.catAC,         Icons.ac_unit),
      (s.catCarpentry,  Icons.carpenter),
      (s.catOther,      Icons.more_horiz),
    ];
    final pendingAsync = ref.watch(pendingRatingsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final query = ref.watch(_searchQueryProvider);

    // Filter categories based on search query
    final indexedCategories = allCategories.asMap().entries.toList();
    final filtered = query.isEmpty
        ? indexedCategories
        : indexedCategories
            .where((e) =>
                e.value.$1.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(s.homeTitle),
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
                pendingLabel: s.homePendingRating,
                rateNowLabel: s.homeRateNow,
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
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: s.homeSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              s.homeSelectService,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      s.homeNoResults,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final originalIndex = filtered[i].key;
                      final (label, icon) = filtered[i].value;
                      final categoryId = _categoryIds[originalIndex];
                      return InkWell(
                        onTap: () {
                          ref
                              .read(bookingNotifierProvider.notifier)
                              .setCategory(categoryId, label);
                          context.go('/booking/description');
                        },
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
    );
  }
}

class _PendingRatingBanner extends StatelessWidget {
  final String providerName;
  final String jobId;
  final String pendingLabel;
  final String rateNowLabel;
  final VoidCallback onRate;
  final VoidCallback onDismiss;

  const _PendingRatingBanner({
    required this.providerName,
    required this.jobId,
    required this.pendingLabel,
    required this.rateNowLabel,
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
            Expanded(
              child: Text(
                pendingLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRate,
              child: Text(
                rateNowLabel,
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
