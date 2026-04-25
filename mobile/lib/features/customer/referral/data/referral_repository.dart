import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../domain/referral_info.dart';

const _tag = 'ReferralRepo';

class ReferralRepository {
  final ApiClient _client;

  ReferralRepository(this._client);

  Future<ReferralInfo> getReferralInfo() async {
    log.d(_tag, 'getReferralInfo start');
    final response = await _client.dio.get('/customers/me/referral');
    return ReferralInfo.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    log.d(_tag, 'applyReferralCode start',
        data: {'codeLen': code.trim().length});
    final response = await _client.dio.post(
      '/customers/referral/apply',
      data: {'code': code.trim().toUpperCase()},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.read(apiClientProvider));
});
