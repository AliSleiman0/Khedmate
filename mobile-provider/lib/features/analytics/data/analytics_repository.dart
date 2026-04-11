import '../../../core/api/api_client.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  final ApiClient _client;
  AnalyticsRepository(this._client);

  /// GET /api/providers/me/analytics/earnings?period=Last30Days
  Future<EarningsAnalytics> getEarnings(String period) async {
    final response = await _client.dio.get(
      '/providers/me/analytics/earnings',
      queryParameters: {'period': period},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data == null) return EarningsAnalytics.empty();
    return EarningsAnalytics.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/providers/me/analytics/jobs?period=Last30Days
  Future<JobAnalytics> getJobStats(String period) async {
    final response = await _client.dio.get(
      '/providers/me/analytics/jobs',
      queryParameters: {'period': period},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data == null) return JobAnalytics.empty();
    return JobAnalytics.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/providers/me/analytics/ratings
  Future<RatingAnalytics> getRatingStats() async {
    final response = await _client.dio.get('/providers/me/analytics/ratings');
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data == null) return RatingAnalytics.empty();
    return RatingAnalytics.fromJson(data as Map<String, dynamic>);
  }
}
