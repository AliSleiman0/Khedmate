import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

class AiRepository {
  final ApiClient _client;

  AiRepository(this._client);

  Future<String> improveDescription({
    required String roughDescription,
    required String categoryName,
  }) async {
    final response = await _client.dio.post(
      '/ai/improve-description',
      data: {
        'roughDescription': roughDescription,
        'categoryName': categoryName,
      },
    );
    return response.data['data']['improvedDescription'] as String;
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.read(apiClientProvider));
});
