import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../data/earnings_repository.dart';
import 'earnings_provider.dart';

class PayoutStatusScreen extends ConsumerStatefulWidget {
  const PayoutStatusScreen({super.key});

  @override
  ConsumerState<PayoutStatusScreen> createState() =>
      _PayoutStatusScreenState();
}

class _PayoutStatusScreenState extends ConsumerState<PayoutStatusScreen> {
  bool _onboarding = false;

  Future<void> _startOnboarding() async {
    setState(() => _onboarding = true);
    try {
      final repo = ref.read(earningsRepositoryProvider);
      final data = await repo.getStripeOnboardingUrl();
      final url = data['onboardingUrl'] as String;

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await ref.read(earningsSummaryProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.read(ref).payoutOnboardingError,
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _onboarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final summaryAsync = ref.watch(earningsSummaryProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.payoutTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: summaryAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => Center(
            child: Text(s.payoutLoadError,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
          ),
          data: (summary) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: s.pendingBalance,
                        value:
                            _fmt(summary.pendingBalance, summary.currency),
                        subtitle: s.pendingBalanceSub,
                        color: AppColors.amber,
                        icon: Icons.hourglass_top,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        label: s.availableBalance,
                        value:
                            _fmt(summary.availableBalance, summary.currency),
                        subtitle: s.availableBalanceSub,
                        color: AppColors.success,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  s.stripeConnectTitle,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                if (summary.stripeConnectStatus == 'complete')
                  _ConnectedBanner()
                else
                  _OnboardingCard(
                    status: summary.stripeConnectStatus,
                    loading: _onboarding,
                    onTap: _startOnboarding,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(double amount, String currency) {
    final symbol = currency == 'usd' ? '\$' : currency.toUpperCase();
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ConnectedBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Card(
      color: AppColors.success.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.success),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.success, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.stripeConnected,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.stripeConnectedSub,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends ConsumerWidget {
  final String status;
  final bool loading;
  final VoidCallback onTap;

  const _OnboardingCard({
    required this.status,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance,
                color: AppColors.brandBlue, size: 40),
            const SizedBox(height: 16),
            Text(
              s.payoutLinkTitle,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              s.payoutLinkDesc,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        s.payoutLinkBtn,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
