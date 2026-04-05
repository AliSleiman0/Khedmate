import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PendingRatingItem {
  final String jobId;
  final String referenceNumber;
  final String categoryName;
  final DateTime paidAt;
  final DateTime expiresAt;
  final String rateTarget;

  PendingRatingItem({
    required this.jobId,
    required this.referenceNumber,
    required this.categoryName,
    required this.paidAt,
    required this.expiresAt,
    required this.rateTarget,
  });

  factory PendingRatingItem.fromJson(Map<String, dynamic> json) =>
      PendingRatingItem(
        jobId: (json['jobId'] ?? '').toString(),
        referenceNumber: json['referenceNumber'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(hours: 48)),
        rateTarget: json['rateTarget'] as String? ?? '',
      );
}

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

  Future<List<PendingRatingItem>> getPendingRatings() async {
    final response = await _client.dio.get('/ratings/pending');
    final data = response.data as Map<String, dynamic>;
    final items = (data['data']['pendingRatings'] as List?) ?? [];
    return items
        .map((e) => PendingRatingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ApiClient());
});
