import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

final analyticsPeriodProvider = StateProvider<String>((ref) => 'Last30Days');

final analyticsProvider =
    FutureProvider.autoDispose<AnalyticsDashboard>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final repo = ref.read(analyticsRepositoryProvider);

  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final results = await Future.wait([
    repo.getEarnings(period),
    repo.getJobStats(period),
    repo.getRatingStats(),
  ]);

  return AnalyticsDashboard(
    earnings: results[0] as EarningsAnalytics,
    jobs: results[1] as JobAnalytics,
    ratings: results[2] as RatingAnalytics,
  );
});
