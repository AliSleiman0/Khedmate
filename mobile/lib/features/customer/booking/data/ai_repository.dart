import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';

const _tag = 'AiRepo';

class AiRepository {
  final ApiClient _client;

  AiRepository(this._client);

  Future<String> improveDescription({
    required String roughDescription,
    required String categoryName,
  }) async {
    log.d(_tag, 'improve start', data: {
      'category': categoryName,
      'inputLen': roughDescription.length,
    });
    try {
      final response = await _client.dio.post(
        '/ai/improve-description',
        data: {
          'roughDescription': roughDescription,
          'categoryName': categoryName,
        },
      );
      final improved =
          response.data['data']['improvedDescription'] as String;
      log.i(_tag, 'improve ok', data: {'outputLen': improved.length});
      return improved;
    } on DioException catch (e) {
      log.e(_tag, 'improve failed', error: e);
      rethrow;
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.read(apiClientProvider));
});
