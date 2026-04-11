import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/subscription_info.dart';

class SubscriptionApiException implements Exception {
  final String errorCode;
  SubscriptionApiException(this.errorCode);
}

class SubscriptionRepository {
  final ApiClient _client;
  SubscriptionRepository(this._client);

  /// GET /api/providers/me/subscription
  /// Returns null if provider has no active/past-due subscription.
  Future<SubscriptionInfo?> getSubscription() async {
    try {
      final response = await _client.dio.get('/providers/me/subscription');
      final data = (response.data as Map<String, dynamic>)['data'];
      if (data == null) return null;
      return SubscriptionInfo.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /api/providers/me/subscription/setup-intent
  /// Returns the Stripe SetupIntent client secret so Flutter can show PaymentSheet.
  Future<String> getSetupIntentClientSecret() async {
    final response = await _client.dio.get('/providers/me/subscription/setup-intent');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['clientSecret'] as String;
  }

  /// POST /api/providers/me/subscription
  /// Body: { paymentMethodId }
  Future<void> subscribe(String paymentMethodId) async {
    try {
      await _client.dio.post(
        '/providers/me/subscription',
        data: {'paymentMethodId': paymentMethodId},
      );
    } on DioException catch (e) {
      final error = (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      if (error != null) throw SubscriptionApiException(error);
      rethrow;
    }
  }

  /// DELETE /api/providers/me/subscription
  /// Returns the date when the subscription will end (cancelsAt).
  Future<DateTime?> cancelSubscription() async {
    try {
      final response = await _client.dio.delete('/providers/me/subscription');
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      final cancelsAt = data?['cancelsAt'] as String?;
      return cancelsAt != null ? DateTime.parse(cancelsAt) : null;
    } on DioException catch (e) {
      final error = (e.response?.data as Map<String, dynamic>?)?['error'] as String?;
      if (error != null) throw SubscriptionApiException(error);
      rethrow;
    }
  }
}
