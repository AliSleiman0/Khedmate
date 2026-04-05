import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import 'earnings_provider.dart';

class EarningsPage extends ConsumerWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final txAsync = ref.watch(earningsTransactionsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'الأرباح',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: 'حساب الدفع',
              onPressed: () => context.push('/payout-status'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(earningsSummaryProvider.notifier).refresh();
            await ref.read(earningsTransactionsProvider.notifier).refresh();
          },
          child: summaryAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
            error: (e, _) => Center(
              child: Text('تعذّر تحميل الأرباح',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ),
            data: (summary) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'هذا الشهر',
                        value: _fmt(summary.totalEarnedThisMonth, summary.currency),
                        icon: Icons.calendar_month,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'في الانتظار',
                        value: _fmt(summary.pendingBalance, summary.currency),
                        icon: Icons.hourglass_top,
                        color: AppColors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  label: 'إجمالي الأرباح',
                  value: _fmt(summary.totalEarnedAllTime, summary.currency),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.success,
                ),

                // Stripe onboarding banner if not connected
                if (summary.stripeConnectStatus != 'complete') ...[
                  const SizedBox(height: 16),
                  _StripeBanner(status: summary.stripeConnectStatus),
                ],

                const SizedBox(height: 24),
                const Text(
                  'آخر المعاملات',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                txAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (transactions) => transactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'لا توجد معاملات بعد',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: Colors.grey),
                            ),
                          ),
                        )
                      : Column(
                          children: transactions
                              .map((tx) => _TransactionTile(tx: tx))
                              .toList(),
                        ),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Cairo')),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                    fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}

class _StripeBanner extends StatelessWidget {
  final String status;
  const _StripeBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.amber.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.amber),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ربط حساب الدفع',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'يرجى ربط حساب Stripe لاستلام أرباحك',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/payout-status'),
              child: const Text('ربط',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: AppColors.amber)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final status = tx['status'] as String? ?? '';
    final gross = (tx['grossAmount'] as num?)?.toDouble() ?? 0;
    final commission = (tx['commissionAmount'] as num?)?.toDouble() ?? 0;
    final net = (tx['netAmount'] as num?)?.toDouble() ?? 0;
    final createdAt = tx['createdAt'] != null
        ? DateTime.tryParse(tx['createdAt'] as String)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                      : '-',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.grey),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إجمالي: \$${gross.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Colors.grey)),
                    Text('رسوم: \$${commission.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
                Text(
                  '\$${net.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'Held' => 'محجوز',
      'Released' => 'محوّل',
      'Disputed' => 'نزاع',
      'Paid' => 'مدفوع',
      'Refunded' => 'مسترجع',
      _ => status,
    };
    final color = switch (status) {
      'Released' => AppColors.success,
      'Disputed' => Colors.red,
      'Refunded' => Colors.orange,
      'Held' => AppColors.amber,
      _ => AppColors.brandBlue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}
