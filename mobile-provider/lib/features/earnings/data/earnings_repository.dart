import '../../../core/api/api_client.dart';

class EarningsRepository {
  final ApiClient _client;

  EarningsRepository(this._client);

  Future<Map<String, dynamic>> getEarningsSummary() async {
    final response = await _client.dio.get('/providers/earnings/summary');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get('/payments/my-transactions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['items'] as List);
  }

  Future<Map<String, dynamic>> getStripeOnboardingUrl() async {
    final response = await _client.dio.post('/providers/stripe/onboard');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}
