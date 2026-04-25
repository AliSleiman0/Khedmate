import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'booking_provider.dart';

const _tag = 'BookingSummary';

class BookingSummaryScreen extends ConsumerWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final asyncState = ref.watch(bookingNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.summaryTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: const AppBackButton(),
        ),
        body: asyncState.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (e, _) => _ErrorBody(
            message: e.toString().contains('فشل')
                ? e.toString()
                : s.summaryPaymentFailed,
            onRetry: () {
              log.d(_tag, 'retry tap');
              ref.read(bookingNotifierProvider.notifier).submitBooking();
            },
          ),
          data: (booking) => _SummaryBody(booking: booking),
        ),
      ),
    );
  }
}

class _SummaryBody extends ConsumerStatefulWidget {
  final BookingState booking;

  const _SummaryBody({required this.booking});

  @override
  ConsumerState<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends ConsumerState<_SummaryBody> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.booking.agreedAmount != null) {
      _amountController.text =
          widget.booking.agreedAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final asyncState = ref.watch(bookingNotifierProvider);
    final isLoading = asyncState.isLoading;
    final booking = asyncState.valueOrNull ?? widget.booking;

    final amountEntered =
        booking.agreedAmount != null && booking.agreedAmount! > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (AppConfig.bypassPayments)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QA BUILD — PAYMENTS BYPASSED. Not for production.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              s.summaryYourDetails,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      icon: Icons.category,
                      label: s.summaryServiceType,
                      value: booking.categoryName ?? '-',
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined,
                            color: AppColors.brandBlue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.summaryDescription,
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: Colors.grey)),
                              const SizedBox(height: 4),
                              _ExpandableText(text: booking.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      icon: Icons.location_on_outlined,
                      label: s.summaryLocationLabel,
                      value: booking.address ?? '-',
                    ),
                    if (booking.photos.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(s.summaryPhotos,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: booking.photos
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(f,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              s.summaryPaymentDetails,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: s.summaryEnterAmount,
                        labelStyle: const TextStyle(
                            fontFamily: 'Cairo', color: Colors.grey),
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.brandBlue, width: 2),
                        ),
                        helperText: s.summaryAmountHelper,
                        helperStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey),
                      ),
                      validator: (v) {
                        final amount = double.tryParse(v ?? '');
                        if (amount == null || amount <= 0) {
                          return S.read(ref).summaryAmountInvalid;
                        }
                        if (amount > 10000) {
                          return 'المبلغ الأقصى هو \$10,000';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        final amount = double.tryParse(v);
                        if (amount != null && amount > 0) {
                          ref
                              .read(bookingNotifierProvider.notifier)
                              .setAmount(amount);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'شامل رسوم الخدمة (${(0.20 * 100).toInt()}%)',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (booking.chargedAmount != null &&
                        ((booking.referralDiscountAmount ?? 0) > 0 ||
                            (booking.creditApplied ?? 0) > 0)) ...[
                      const Divider(height: 24),
                      if ((booking.referralDiscountAmount ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.summaryReferralDiscount,
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      color: AppColors.amber)),
                              Text(
                                '-${booking.referralDiscountAmount!.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if ((booking.creditApplied ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.summaryWalletCredit,
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      color: AppColors.success)),
                              Text(
                                '-${booking.creditApplied!.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.summaryTotalDue,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text(
                            '${booking.chargedAmount!.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandBlue),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || !amountEntered
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          log.d(_tag, 'pay blocked',
                              data: {'reason': 'validation_failed'});
                          return;
                        }
                        log.d(_tag, 'pay tap', data: {
                          'amount': booking.agreedAmount,
                          'bypass': AppConfig.bypassPayments,
                        });
                        await ref
                            .read(bookingNotifierProvider.notifier)
                            .submitBooking();
                        final updated =
                            ref.read(bookingNotifierProvider).valueOrNull;
                        if (updated?.createdJobId != null &&
                            context.mounted) {
                          log.i(_tag, 'nav next', data: {
                            'target': '/customer/payment/receipt',
                            'jobId': updated!.createdJobId,
                          });
                          context.go('/customer/payment/receipt');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            s.summaryPayButton,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                s.summarySecurePayment,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.brandBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandableText extends ConsumerStatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  ConsumerState<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends ConsumerState<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textPrimary),
        ),
        if (widget.text.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? s.showLess : s.showMore,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.brandBlue,
                  fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _ErrorBody extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, color: Colors.red, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white),
              child: Text(s.retry,
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}
