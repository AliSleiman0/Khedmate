import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import 'rating_provider.dart';

// Customer tags (positive only — displayed in Arabic)
const _customerTags = [
  ('arrived_on_time',     'وصل في الوقت المحدد'),
  ('clean_worksite',      'عمل نظيف'),
  ('fair_pricing',        'سعر عادل'),
  ('professional',        'محترف'),
  ('would_recommend',     'أنصح به'),
];

class RatingBottomSheet extends ConsumerWidget {
  final String jobId;
  final String providerName;

  const RatingBottomSheet({
    super.key,
    required this.jobId,
    required this.providerName,
  });

  static Future<void> show(
    BuildContext context, {
    required String jobId,
    required String providerName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(jobId: jobId, providerName: providerName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ratingNotifierProvider(jobId));
    final notifier = ref.read(ratingNotifierProvider(jobId).notifier);

    // Auto-dismiss on successful submission
    if (state.isSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop(true);
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Provider avatar + name
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.brandBlue,
                child: Text(
                  providerName.isNotEmpty ? providerName[0].toUpperCase() : 'م',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'كيف كانت تجربتك مع $providerName؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Thumbs row
              Row(
                children: [
                  Expanded(
                    child: _ThumbButton(
                      label: 'ممتاز',
                      icon: Icons.thumb_up_rounded,
                      isSelected: state.isPositive == true,
                      selectedColor: AppColors.brandBlue,
                      onTap: () => notifier.setThumb(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThumbButton(
                      label: 'سيء',
                      icon: Icons.thumb_down_rounded,
                      isSelected: state.isPositive == false,
                      selectedColor: Colors.red.shade600,
                      onTap: () => notifier.setThumb(false),
                    ),
                  ),
                ],
              ),

              // Tags section (only for thumbs up)
              if (state.isPositive == true) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'أخبرنا أكثر',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customerTags.map((tag) {
                    final isSelected = state.selectedTags.contains(tag.$1);
                    return GestureDetector(
                      onTap: () => notifier.toggleTag(tag.$1),
                      child: Chip(
                        label: Text(
                          tag.$2,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor:
                            isSelected ? AppColors.amber : Colors.grey.shade200,
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Error
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isPositive == null || state.isSubmitting
                      ? null
                      : () => notifier.submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'إرسال التقييم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Skip link
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 14,
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

class _ThumbButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ThumbButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
