import '../../../core/api/api_client.dart';

class PaymentRepository {
  final ApiClient _client;

  PaymentRepository(this._client);

  Future<Map<String, dynamic>> createIntent({
    required double amount,
    required String currency,
    required String categoryId,
  }) async {
    final response = await _client.dio.post('/payments/intent', data: {
      'amount': amount,
      'currency': currency,
      'categoryId': categoryId,
    });
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String jobId,
  }) async {
    final response = await _client.dio.post('/payments/confirm', data: {
      'paymentIntentId': paymentIntentId,
      'jobId': jobId,
    });
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
}
