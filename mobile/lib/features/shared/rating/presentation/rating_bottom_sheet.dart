import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import 'rating_provider.dart';

const _customerTagKeys = [
  'arrived_on_time',
  'clean_worksite',
  'fair_pricing',
  'professional',
  'would_recommend',
];

const _providerTagKeys = [
  'easy_to_deal_with',
  'described_problem_accurately',
  'paid_promptly',
];

/// Unified rating sheet. Both roles use thumbs up/down + positive tag chips
/// (matches the backend `/api/ratings` contract). Which tag list and which
/// question text render is determined by `roleProvider`.
class RatingBottomSheet extends ConsumerWidget {
  final String jobId;
  final String otherPartyName;

  const RatingBottomSheet({
    super.key,
    required this.jobId,
    required this.otherPartyName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String jobId,
    required String otherPartyName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        jobId: jobId,
        otherPartyName: otherPartyName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final role = ref.watch(roleProvider) ?? UserRole.customer;
    final isCustomer = role == UserRole.customer;
    final state = ref.watch(ratingNotifierProvider(jobId));
    final notifier = ref.read(ratingNotifierProvider(jobId).notifier);

    final tagLabels = isCustomer
        ? <String, String>{
            'arrived_on_time': s.ratingOnTime,
            'clean_worksite': s.ratingCleanWork,
            'fair_pricing': s.ratingFairPrice,
            'professional': s.ratingProfessional,
            'would_recommend': s.ratingRecommend,
          }
        : <String, String>{
            'easy_to_deal_with': s.ratingEasyDeal,
            'described_problem_accurately': s.ratingAccurateDesc,
            'paid_promptly': s.ratingPromptPay,
          };

    final tagKeys = isCustomer ? _customerTagKeys : _providerTagKeys;
    final submitColor = isCustomer ? AppColors.amber : AppColors.brandBlue;

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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (isCustomer) ...[
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.brandBlue,
                  child: Text(
                    otherPartyName.isNotEmpty
                        ? otherPartyName[0].toUpperCase()
                        : 'م',
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
                  s.ratingQuestion(otherPartyName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ] else ...[
                Text(
                  s.ratingCustomerQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ThumbButton(
                      label: s.ratingGood,
                      icon: Icons.thumb_up_rounded,
                      isSelected: state.isPositive == true,
                      selectedColor: AppColors.brandBlue,
                      onTap: () => notifier.setThumb(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThumbButton(
                      label: s.ratingBad,
                      icon: Icons.thumb_down_rounded,
                      isSelected: state.isPositive == false,
                      selectedColor: Colors.red.shade600,
                      onTap: () => notifier.setThumb(false),
                    ),
                  ),
                ],
              ),
              if (state.isPositive == true) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    s.ratingTellMore,
                    style: const TextStyle(
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
                  children: tagKeys.map((key) {
                    final isSelected = state.selectedTags.contains(key);
                    return GestureDetector(
                      onTap: () => notifier.toggleTag(key),
                      child: Chip(
                        label: Text(
                          tagLabels[key] ?? key,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? AppColors.amber
                            : Colors.grey.shade200,
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  s.ratingSubmitError,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isPositive == null || state.isSubmitting
                      ? null
                      : notifier.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submitColor,
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
                      : Text(
                          s.ratingSubmit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  isCustomer ? s.skip : s.ratingSkip,
                  style: const TextStyle(
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
