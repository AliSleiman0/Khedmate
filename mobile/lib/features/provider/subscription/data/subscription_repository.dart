import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';
import '../domain/subscription_info.dart';

const _tag = 'SubscriptionRepo';

class SubscriptionApiException implements Exception {
  final String errorCode;
  SubscriptionApiException(this.errorCode);
}

class SubscriptionRepository {
  final ApiClient _client;
  SubscriptionRepository(this._client);

  Future<SubscriptionInfo?> getSubscription() async {
    log.d(_tag, 'getSubscription start');
    try {
      final response = await _client.dio.get('/providers/me/subscription');
      final data = (response.data as Map<String, dynamic>)['data'];
      if (data == null) {
        log.i(_tag, 'getSubscription empty');
        return null;
      }
      final info = SubscriptionInfo.fromJson(data as Map<String, dynamic>);
      log.i(_tag, 'getSubscription ok', data: {'status': info.status});
      return info;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        log.i(_tag, 'getSubscription 404');
        return null;
      }
      log.e(_tag, 'getSubscription failed', error: e);
      rethrow;
    }
  }

  Future<String> getSetupIntentClientSecret() async {
    log.d(_tag, 'setup intent start');
    final response =
        await _client.dio.get('/providers/me/subscription/setup-intent');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final secret = data['clientSecret'] as String;
    log.i(_tag, 'setup intent ok',
        data: {'clientSecret': redactToken(secret)});
    return secret;
  }

  Future<void> subscribe(String paymentMethodId) async {
    log.d(_tag, 'subscribe start',
        data: {'paymentMethodId': redactToken(paymentMethodId)});
    try {
      await _client.dio.post(
        '/providers/me/subscription',
        data: {'paymentMethodId': paymentMethodId},
      );
      log.i(_tag, 'subscribe ok');
    } on DioException catch (e) {
      final error =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      log.e(_tag, 'subscribe failed', error: e, data: {'code': error});
      if (error != null) throw SubscriptionApiException(error);
      rethrow;
    }
  }

  Future<DateTime?> cancelSubscription() async {
    log.d(_tag, 'cancel start');
    try {
      final response =
          await _client.dio.delete('/providers/me/subscription');
      final data = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      final cancelsAt = data?['cancelsAt'] as String?;
      log.i(_tag, 'cancel ok', data: {'cancelsAt': cancelsAt});
      return cancelsAt != null ? DateTime.parse(cancelsAt) : null;
    } on DioException catch (e) {
      final error =
          (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      log.e(_tag, 'cancel failed', error: e, data: {'code': error});
      if (error != null) throw SubscriptionApiException(error);
      rethrow;
    }
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});
