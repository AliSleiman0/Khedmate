import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../domain/analytics_models.dart';
import 'analytics_provider.dart';

const _tag = 'AnalyticsScreen';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final dashAsync = ref.watch(analyticsProvider);
    final period = ref.watch(analyticsPeriodProvider);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          leading: const AppBackButton(),
          title: Text(
            s.analyticsTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            _PeriodSelector(currentPeriod: period),
            Expanded(
              child: dashAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.brandBlue),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.analyticsLoadError,
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(analyticsProvider),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                ),
                data: (dash) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _EarningsSection(earnings: dash.earnings),
                    const SizedBox(height: 24),
                    _JobStatsSection(jobs: dash.jobs),
                    const SizedBox(height: 24),
                    _RatingsSection(ratings: dash.ratings),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.currentPeriod});
  final String currentPeriod;

  static const _periods = [
    ('Last7Days', '7 أيام', '7 Days'),
    ('Last30Days', '30 يوم', '30 Days'),
    ('Last3Months', '3 أشهر', '3 Months'),
    ('AllTime', 'الكل', 'All Time'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = S.of(ref).isAr;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periods.map((p) {
            final isSelected = p.$1 == currentPeriod;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  isAr ? p.$2 : p.$3,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color:
                        isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  log.d(_tag, 'period chip tap', data: {'period': p.$1});
                  ref.read(analyticsPeriodProvider.notifier).state = p.$1;
                },
                selectedColor: AppColors.brandBlue,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.brandBlue
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EarningsSection extends ConsumerWidget {
  const _EarningsSection({required this.earnings});
  final EarningsAnalytics earnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final isAr = s.isAr;
    final locale = isAr ? 'ar' : 'en';
    final numFmt = NumberFormat('#,##0.##', locale);

    final changePercent = earnings.changePercent;
    final isPositiveChange = (changePercent ?? 0) >= 0;

    return _SectionCard(
      title: s.analyticsEarningsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.analyticsNetEarnings,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.analyticsSAR} ${numFmt.format(earnings.currentPeriodEarnings)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (changePercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositiveChange
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveChange
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: isPositiveChange
                              ? AppColors.success
                              : AppColors.danger,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changePercent.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isPositiveChange
                                ? AppColors.success
                                : AppColors.danger,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${s.analyticsPending}: ${s.analyticsSAR} ${numFmt.format(earnings.pendingEarnings)}',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (earnings.chartDataPoints.isEmpty)
            _NoDataWidget(text: s.analyticsNoData)
          else
            SizedBox(
              height: 160,
              child: _EarningsLineChart(
                  dataPoints: earnings.chartDataPoints, isAr: isAr),
            ),
        ],
      ),
    );
  }
}

class _EarningsLineChart extends StatelessWidget {
  const _EarningsLineChart({required this.dataPoints, required this.isAr});
  final List<ChartDataPoint> dataPoints;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final locale = isAr ? 'ar' : 'en';
    final dateLabels = dataPoints
        .map((p) => DateFormat('d MMM', locale).format(p.date))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (dataPoints.length / 4)
                  .ceilToDouble()
                  .clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dateLabels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  dateLabels[idx],
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.amber,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.amber.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobStatsSection extends ConsumerWidget {
  const _JobStatsSection({required this.jobs});
  final JobAnalytics jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final isAr = s.isAr;
    final locale = isAr ? 'ar' : 'en';
    final numFmt = NumberFormat('#,##0.##', locale);

    return _SectionCard(
      title: s.analyticsJobsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCell(
                  label: s.analyticsCompleted,
                  value: '${jobs.completedJobs}'),
              _StatCell(
                  label: s.analyticsAcceptRate,
                  value: '${jobs.acceptanceRate.toStringAsFixed(1)}%'),
              _StatCell(
                  label: s.analyticsAvgValue,
                  value:
                      '${s.analyticsSAR} ${numFmt.format(jobs.avgJobValueNet)}'),
              _StatCell(
                  label: isAr ? 'مرفوض' : 'Rejected',
                  value: '${jobs.rejectedJobs}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            s.analyticsTopCategories,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (jobs.topCategories.isEmpty)
            _NoDataWidget(text: s.analyticsNoData)
          else
            SizedBox(
              height: 180,
              child: _CategoriesBarChart(
                  categories: jobs.topCategories, isAr: isAr),
            ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _CategoriesBarChart extends StatelessWidget {
  const _CategoriesBarChart({required this.categories, required this.isAr});
  final List<CategoryStat> categories;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final shown = categories.take(5).toList();
    final maxVal = shown.fold<double>(
        0,
        (prev, c) =>
            c.jobCount.toDouble() > prev ? c.jobCount.toDouble() : prev);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= shown.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: RotatedBox(
                    quarterTurns: isAr ? 1 : -1,
                    child: Text(
                      shown[idx].categoryName,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: shown.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.jobCount.toDouble(),
                color: AppColors.brandBlue,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RatingsSection extends ConsumerWidget {
  const _RatingsSection({required this.ratings});
  final RatingAnalytics ratings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);

    return _SectionCard(
      title: s.analyticsRatingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.analyticsPositiveRate,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ratings.positiveRatePct != null
                          ? '${ratings.positiveRatePct!.toStringAsFixed(1)}%'
                          : '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.thumb_up_rounded,
                        color: AppColors.success, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '${s.analyticsTotalRatings}: ${ratings.totalRatings}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (ratings.topPositiveTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              s.analyticsTopTags,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ratings.topPositiveTags.take(3).map((tag) {
                return Chip(
                  label: Text(tag,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Colors.white)),
                  backgroundColor: AppColors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }).toList(),
            ),
          ],
          if (ratings.recentRatings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              s.analyticsRatingTrend,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: _RatingSparkline(ratings: ratings.recentRatings),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _NoDataWidget(text: s.analyticsNoData),
            ),
        ],
      ),
    );
  }
}

class _RatingSparkline extends StatelessWidget {
  const _RatingSparkline({required this.ratings});
  final List<RecentRating> ratings;

  @override
  Widget build(BuildContext context) {
    final spots = ratings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.isPositive ? 1.0 : 0.0);
    }).toList();

    return LineChart(
      LineChartData(
        minY: -0.2,
        maxY: 1.2,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.brandBlue,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isPositive = spot.y >= 0.5;
                return FlDotCirclePainter(
                  radius: 5,
                  color: isPositive ? AppColors.success : AppColors.danger,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NoDataWidget extends StatelessWidget {
  const _NoDataWidget({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
              fontSize: 14),
        ),
      ),
    );
  }
}
