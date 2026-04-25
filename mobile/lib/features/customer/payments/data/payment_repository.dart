import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';

const _tag = 'PaymentRepo';

class PaymentRepository {
  final ApiClient _client;

  PaymentRepository(this._client);

  Future<Map<String, dynamic>> createIntent({
    required double amount,
    required String currency,
    required String categoryId,
  }) async {
    log.d(_tag, 'createIntent start',
        data: {'amount': amount, 'currency': currency, 'category': categoryId});
    try {
      final response = await _client.dio.post('/payments/intent', data: {
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
      });
      return (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'createIntent failed', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String jobId,
  }) async {
    log.d(_tag, 'confirmPayment start',
        data: {'paymentIntentId': paymentIntentId, 'jobId': jobId});
    try {
      final response = await _client.dio.post('/payments/confirm', data: {
        'paymentIntentId': paymentIntentId,
        'jobId': jobId,
      });
      return (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'confirmPayment failed',
          error: e, data: {'jobId': jobId});
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    log.d(_tag, 'getMyTransactions start',
        data: {'page': page, 'pageSize': pageSize});
    final response = await _client.dio.get(
      '/payments/my-transactions',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['items'] as List);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});
