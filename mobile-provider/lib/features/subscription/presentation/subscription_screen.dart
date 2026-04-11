import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_info.dart';
import 'subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _inlineError;
  bool _paymentInProgress = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final subAsync = ref.watch(subscriptionProvider);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.subTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: subAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandBlue),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.subLoadError,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(subscriptionProvider),
                  child: Text(s.retry),
                ),
              ],
            ),
          ),
          data: (sub) => sub == null
              ? _UnsubscribedView(
                  onSubscribe: _handleSubscribe,
                  inlineError: _inlineError,
                  inProgress: _paymentInProgress,
                )
              : _SubscribedView(
                  sub: sub,
                  onCancel: _handleCancel,
                ),
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    setState(() {
      _inlineError = null;
      _paymentInProgress = true;
    });

    try {
      // 1. Obtain a SetupIntent client secret from the backend.
      final repo = ref.read(subscriptionRepositoryProvider);
      final String clientSecret;
      try {
        clientSecret = await repo.getSetupIntentClientSecret();
      } on SubscriptionApiException catch (e) {
        final s = S.of(ref);
        setState(() {
          _inlineError = switch (e.errorCode) {
            'PROVIDER_NOT_ACTIVE' => s.subErrorNotActive,
            'ALREADY_SUBSCRIBED'  => s.subErrorAlready,
            'STRIPE_ERROR'        => s.subErrorStripe,
            _                    => s.errorGeneric,
          };
          _paymentInProgress = false;
        });
        return;
      }

      // 2. Present Stripe PaymentSheet to collect payment method.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Khudmati',
          style: ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 3. After successful sheet confirmation, retrieve the PaymentMethod ID.
      //    The backend can retrieve the paymentMethod from the SetupIntent server-side.
      //    We pass the clientSecret's SetupIntent ID as the paymentMethodId placeholder.
      final siId = clientSecret.split('_secret_').first; // e.g. "seti_xxxx"
      final error = await ref.read(subscriptionProvider.notifier).subscribe(siId);
      if (!mounted) return;
      if (error != null) {
        setState(() => _inlineError = error);
      } else {
        _showSnackBar(S.of(ref).subSuccess, isError: false);
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      // User cancelled the payment sheet — don't show an error.
      if (e.error.code == FailureCode.Canceled) {
        setState(() => _inlineError = null);
      } else {
        setState(() => _inlineError = S.of(ref).subErrorStripe);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineError = S.of(ref).subErrorStripe);
    } finally {
      if (mounted) setState(() => _paymentInProgress = false);
    }
  }

  Future<void> _handleCancel() async {
    final s = S.of(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(s.subCancelConfirmTitle,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Text(s.subCancelConfirmBody,
              style: const TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.subCancelConfirmNo,
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(s.subCancelConfirmYes,
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref.read(subscriptionProvider.notifier).cancel();
    if (!mounted) return;
    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar(S.of(ref).subCancelSuccess, isError: false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }
}

// ── Unsubscribed view ────────────────────────────────────────────────────────

class _UnsubscribedView extends ConsumerWidget {
  const _UnsubscribedView({
    required this.onSubscribe,
    required this.inlineError,
    required this.inProgress,
  });

  final VoidCallback onSubscribe;
  final String? inlineError;
  final bool inProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4F72), Color(0xFF2E86AB)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    s.subPower,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '99 ${s.analyticsSAR} / ${s.isAr ? "شهرياً" : "month"}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Benefits
        Text(
          s.subBenefitsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _BenefitRow(text: s.subBenefit1),
        _BenefitRow(text: s.subBenefit2),
        _BenefitRow(text: s.subBenefit3),

        const SizedBox(height: 24),

        // Current plan notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${s.subCurrentPlan}: ${s.subStandard} (15%)',
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

        const SizedBox(height: 24),

        if (inlineError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              inlineError!,
              style: const TextStyle(
                  color: AppColors.danger, fontFamily: 'Cairo', fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: inProgress ? null : onSubscribe,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: inProgress
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  s.subSubscribe,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subscribed view ──────────────────────────────────────────────────────────

class _SubscribedView extends ConsumerWidget {
  const _SubscribedView({required this.sub, required this.onCancel});

  final SubscriptionInfo sub;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final isAr = s.isAr;
    final locale = isAr ? 'ar' : 'en';
    final dateStr = DateFormat('d MMMM yyyy', locale).format(sub.currentPeriodEnd);
    final isPastDue = sub.status == 'PastDue';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PastDue warning banner
        if (isPastDue)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.subPaymentFailed,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        // Header card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4F72), Color(0xFF2E86AB)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.amber, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.subPower,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPastDue ? AppColors.amber : AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPastDue ? s.subPastDueStatus : s.subActiveStatus,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PlanStat(
                    label: s.subCommission,
                    value: '${sub.commissionRate.toStringAsFixed(0)}%',
                  ),
                  _PlanStat(
                    label: s.subPriority,
                    value: isAr ? '30 ث' : '30 s',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Billing info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.brandBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${sub.cancelsAtPeriodEnd ? s.subCancelsAt : s.subNextBilling}: $dateStr',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        if (!sub.cancelsAtPeriodEnd) ...[
          const SizedBox(height: 32),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              s.subCancel,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo')),
      ],
    );
  }
}
