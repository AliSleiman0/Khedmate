class ChartDataPoint {
  final DateTime date;
  final double amount;
  const ChartDataPoint({required this.date, required this.amount});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) => ChartDataPoint(
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class EarningsAnalytics {
  final double currentPeriodEarnings;
  final double? previousPeriodEarnings;
  final double? changePercent;
  final double pendingEarnings;
  final String currency;
  final List<ChartDataPoint> chartDataPoints;

  const EarningsAnalytics({
    required this.currentPeriodEarnings,
    this.previousPeriodEarnings,
    this.changePercent,
    required this.pendingEarnings,
    required this.currency,
    required this.chartDataPoints,
  });

  factory EarningsAnalytics.fromJson(Map<String, dynamic> json) {
    final points = (json['chartDataPoints'] as List<dynamic>? ?? [])
        .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return EarningsAnalytics(
      currentPeriodEarnings:
          (json['currentPeriodEarnings'] as num?)?.toDouble() ?? 0.0,
      previousPeriodEarnings:
          (json['previousPeriodEarnings'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
      chartDataPoints: points,
    );
  }

  static EarningsAnalytics empty() => const EarningsAnalytics(
        currentPeriodEarnings: 0,
        pendingEarnings: 0,
        currency: 'SAR',
        chartDataPoints: [],
      );
}

class CategoryStat {
  final String categoryId;
  final String categoryName;
  final int jobCount;

  const CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.jobCount,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        jobCount: (json['jobCount'] as num?)?.toInt() ?? 0,
      );
}

class JobAnalytics {
  final int completedJobs;
  final int rejectedJobs;
  final int expiredJobs;
  final double acceptanceRate;
  final double avgJobValueNet;
  final String currency;
  final List<CategoryStat> topCategories;

  const JobAnalytics({
    required this.completedJobs,
    required this.rejectedJobs,
    required this.expiredJobs,
    required this.acceptanceRate,
    required this.avgJobValueNet,
    required this.currency,
    required this.topCategories,
  });

  factory JobAnalytics.fromJson(Map<String, dynamic> json) {
    final cats = (json['topCategories'] as List<dynamic>? ?? [])
        .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
        .toList();
    return JobAnalytics(
      completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
      rejectedJobs: (json['rejectedJobs'] as num?)?.toInt() ?? 0,
      expiredJobs: (json['expiredJobs'] as num?)?.toInt() ?? 0,
      acceptanceRate: (json['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      avgJobValueNet: (json['avgJobValueNet'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
      topCategories: cats,
    );
  }

  static JobAnalytics empty() => const JobAnalytics(
        completedJobs: 0,
        rejectedJobs: 0,
        expiredJobs: 0,
        acceptanceRate: 0,
        avgJobValueNet: 0,
        currency: 'SAR',
        topCategories: [],
      );
}

class RecentRating {
  final bool isPositive;
  final DateTime date;
  const RecentRating({required this.isPositive, required this.date});

  factory RecentRating.fromJson(Map<String, dynamic> json) => RecentRating(
        isPositive: json['isPositive'] as bool? ?? true,
        date: DateTime.parse(json['date'] as String),
      );
}

class RatingAnalytics {
  final double? positiveRatePct;
  final int totalRatings;
  final int positiveCount;
  final List<String> topPositiveTags;
  final List<String> topNegativeTags;
  final List<RecentRating> recentRatings;

  const RatingAnalytics({
    this.positiveRatePct,
    required this.totalRatings,
    required this.positiveCount,
    required this.topPositiveTags,
    required this.topNegativeTags,
    required this.recentRatings,
  });

  factory RatingAnalytics.fromJson(Map<String, dynamic> json) {
    final recent = (json['recentRatings'] as List<dynamic>? ?? [])
        .map((e) => RecentRating.fromJson(e as Map<String, dynamic>))
        .toList();
    return RatingAnalytics(
      positiveRatePct: (json['positiveRatePct'] as num?)?.toDouble(),
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      positiveCount: (json['positiveCount'] as num?)?.toInt() ?? 0,
      topPositiveTags: List<String>.from(json['topPositiveTags'] as List? ?? []),
      topNegativeTags: List<String>.from(json['topNegativeTags'] as List? ?? []),
      recentRatings: recent,
    );
  }

  static RatingAnalytics empty() => const RatingAnalytics(
        totalRatings: 0,
        positiveCount: 0,
        topPositiveTags: [],
        topNegativeTags: [],
        recentRatings: [],
      );
}

class AnalyticsDashboard {
  final EarningsAnalytics earnings;
  final JobAnalytics jobs;
  final RatingAnalytics ratings;

  const AnalyticsDashboard({
    required this.earnings,
    required this.jobs,
    required this.ratings,
  });
}
