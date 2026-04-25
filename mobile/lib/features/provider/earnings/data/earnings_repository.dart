import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';

const _tag = 'EarningsRepo';

class EarningsRepository {
  final ApiClient _client;

  EarningsRepository(this._client);

  Future<Map<String, dynamic>> getEarningsSummary() async {
    log.d(_tag, 'summary start');
    final response = await _client.dio.get('/providers/earnings/summary');
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    log.d(_tag, 'transactions start',
        data: {'page': page, 'pageSize': pageSize});
    final response =
        await _client.dio.get('/payments/my-transactions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['items'] as List);
  }

  Future<Map<String, dynamic>> getStripeOnboardingUrl() async {
    log.d(_tag, 'stripe onboard start');
    try {
      final response = await _client.dio.post('/providers/stripe/onboard');
      log.i(_tag, 'stripe onboard ok');
      return (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'stripe onboard failed', error: e);
      rethrow;
    }
  }
}

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository(ref.watch(apiClientProvider));
});
