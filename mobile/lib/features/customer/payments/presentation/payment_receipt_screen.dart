import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../booking/presentation/booking_provider.dart';

class PaymentReceiptScreen extends ConsumerWidget {
  const PaymentReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final booking = ref.read(bookingNotifierProvider).valueOrNull;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.receiptSuccessTitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.receiptProcessing,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ReceiptRow(
                          label: s.receiptAmountPaid,
                          value:
                              '${(booking?.chargedAmount ?? booking?.agreedAmount)?.toStringAsFixed(2) ?? '-'} SAR',
                          valueStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandBlue,
                          ),
                        ),
                        if (booking?.referralDiscountAmount != null &&
                            (booking!.referralDiscountAmount ?? 0) > 0) ...[
                          const Divider(height: 16),
                          _ReceiptRow(
                            label: s.receiptReferralDiscount,
                            value:
                                '-${booking.referralDiscountAmount!.toStringAsFixed(2)} SAR',
                            valueStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        if (booking?.creditApplied != null &&
                            (booking!.creditApplied ?? 0) > 0) ...[
                          const Divider(height: 16),
                          _ReceiptRow(
                            label: s.receiptCreditApplied,
                            value:
                                '-${booking.creditApplied!.toStringAsFixed(2)} SAR',
                            valueStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        const Divider(height: 24),
                        _ReceiptRow(
                          label: s.receiptOrderNo,
                          value: booking?.referenceNumber ?? '-',
                        ),
                        const Divider(height: 16),
                        _ReceiptRow(
                          label: s.receiptPaymentMethod,
                          value: 'Stripe',
                        ),
                        const Divider(height: 16),
                        _ReceiptRow(
                          label: s.receiptStatusLabel,
                          value: s.statusPaid,
                          valueStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (booking?.createdJobId != null) {
                        context.go('/customer/booking/confirmation');
                      } else {
                        context.go('/customer/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      s.receiptViewOrder,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(bookingNotifierProvider.notifier).reset();
                    context.go('/customer/home');
                  },
                  child: Text(
                    s.backHome,
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 14, color: Colors.grey)),
        Text(value,
            style: valueStyle ??
                const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textPrimary)),
      ],
    );
  }
}
