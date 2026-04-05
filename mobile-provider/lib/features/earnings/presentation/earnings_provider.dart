import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/earnings_repository.dart';

final _apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository(ref.read(_apiClientProvider));
});

// ── Earnings Summary ──────────────────────────────────────────────────────────

class EarningsSummary {
  final double pendingBalance;
  final double availableBalance;
  final double totalEarnedAllTime;
  final double totalEarnedThisMonth;
  final String currency;
  final String stripeConnectStatus; // not_started | pending | complete

  const EarningsSummary({
    required this.pendingBalance,
    required this.availableBalance,
    required this.totalEarnedAllTime,
    required this.totalEarnedThisMonth,
    required this.currency,
    required this.stripeConnectStatus,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) => EarningsSummary(
        pendingBalance: (json['pendingBalance'] as num).toDouble(),
        availableBalance: (json['availableBalance'] as num).toDouble(),
        totalEarnedAllTime: (json['totalEarnedAllTime'] as num).toDouble(),
        totalEarnedThisMonth: (json['totalEarnedThisMonth'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'usd',
        stripeConnectStatus: json['stripeConnectStatus'] as String? ?? 'not_started',
      );
}

class EarningsSummaryNotifier extends AsyncNotifier<EarningsSummary> {
  @override
  Future<EarningsSummary> build() async {
    final repo = ref.read(earningsRepositoryProvider);
    final data = await repo.getEarningsSummary();
    return EarningsSummary.fromJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(earningsRepositoryProvider);
      final data = await repo.getEarningsSummary();
      return EarningsSummary.fromJson(data);
    });
  }
}

final earningsSummaryProvider =
    AsyncNotifierProvider<EarningsSummaryNotifier, EarningsSummary>(
        EarningsSummaryNotifier.new);

// ── Transactions ──────────────────────────────────────────────────────────────

class EarningsTransactionsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.read(earningsRepositoryProvider);
    return repo.getMyTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(earningsRepositoryProvider);
      return repo.getMyTransactions();
    });
  }
}

final earningsTransactionsProvider =
    AsyncNotifierProvider<EarningsTransactionsNotifier, List<Map<String, dynamic>>>(
        EarningsTransactionsNotifier.new);
