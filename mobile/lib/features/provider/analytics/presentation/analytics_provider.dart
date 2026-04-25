import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

const _tag = 'AnalyticsNotifier';

final analyticsPeriodProvider = StateProvider<String>((ref) => 'Last30Days');

final analyticsProvider =
    FutureProvider.autoDispose<AnalyticsDashboard>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  log.d(_tag, 'load start', data: {'period': period, 'cache': 'miss'});
  final repo = ref.read(analyticsRepositoryProvider);

  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  log.d(_tag, 'parallel fetch start');
  try {
    final results = await Future.wait([
      repo.getEarnings(period),
      repo.getJobStats(period),
      repo.getRatingStats(),
    ]);

    log.i(_tag, 'parallel fetch ok', data: {'period': period});
    return AnalyticsDashboard(
      earnings: results[0] as EarningsAnalytics,
      jobs: results[1] as JobAnalytics,
      ratings: results[2] as RatingAnalytics,
    );
  } catch (e, st) {
    log.e(_tag, 'parallel fetch failed',
        error: e, stack: st, data: {'period': period});
    rethrow;
  }
});
