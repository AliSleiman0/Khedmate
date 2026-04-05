import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class RatingRepository {
  final ApiClient _client;

  RatingRepository(this._client);

  Future<bool> submitRating({
    required String jobId,
    required bool isPositive,
    required List<String> tags,
  }) async {
    final response = await _client.dio.post('/ratings', data: {
      'jobId': jobId,
      'isPositive': isPositive,
      'tags': tags,
    });
    final data = response.data as Map<String, dynamic>;
    return data['success'] as bool? ?? false;
  }

  Future<Set<String>> getPendingRatingJobIds() async {
    final response = await _client.dio.get('/ratings/pending');
    final data = response.data as Map<String, dynamic>;
    final items = (data['data']['pendingRatings'] as List?) ?? [];
    return items
        .map((e) => (e as Map<String, dynamic>)['jobId'].toString())
        .toSet();
  }
}

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ApiClient());
});
