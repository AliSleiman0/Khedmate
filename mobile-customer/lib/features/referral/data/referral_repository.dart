import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/referral_info.dart';

class ReferralRepository {
  final ApiClient _client;

  ReferralRepository(this._client);

  Future<ReferralInfo> getReferralInfo() async {
    final response = await _client.dio.get('/customers/me/referral');
    return ReferralInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Returns the referrer's name and discount pct on success.
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final response = await _client.dio.post(
      '/customers/referral/apply',
      data: {'code': code.trim().toUpperCase()},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ApiClient());
});
