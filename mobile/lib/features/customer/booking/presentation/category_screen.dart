import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/domain/service_category.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'booking_provider.dart';

const _tag = 'CategoryScreen';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final asyncCategories = ref.watch(categoriesProvider);
    final locale = ref.watch(localeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.catScreenTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: const AppBackButton(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                s.catSelectType,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(categoriesProvider),
                  child: asyncCategories.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              locale.languageCode == 'ar'
                                  ? 'تعذر تحميل القائمة. اسحب للأسفل للتحديث.'
                                  : 'Failed to load. Pull down to refresh.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    data: (categories) {
                      if (categories.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                s.catScreenTitle,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final label = cat.localizedName(locale);
                          return _CategoryCard(
                            category: cat,
                            label: label,
                            onTap: () {
                              log.d(_tag, 'category tap',
                                  data: {'id': cat.slug});
                              ref
                                  .read(bookingNotifierProvider.notifier)
                                  .setCategory(cat.slug, label);
                              context.go('/customer/booking/description');
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final String label;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 70,
              color: AppColors.brandBlue,
              child: Center(
                child: Icon(category.iconData,
                    size: 36, color: AppColors.amber),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
