import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

class CompletedJobSummary {
  final String id;
  final String referenceNumber;
  final String categoryName;
  final String district;
  final double netAmount;
  final DateTime completedAt;

  const CompletedJobSummary({
    required this.id,
    required this.referenceNumber,
    required this.categoryName,
    required this.district,
    required this.netAmount,
    required this.completedAt,
  });

  factory CompletedJobSummary.fromJson(Map<String, dynamic> json) =>
      CompletedJobSummary(
        id: (json['jobId'] ?? json['id'] ?? '').toString(),
        referenceNumber: json['referenceNumber'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        district: json['district'] as String? ?? '',
        netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toLocal()
            : DateTime.now(),
      );
}

final completedJobsProvider =
    FutureProvider.autoDispose<List<CompletedJobSummary>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.dio.get(
    '/providers/me/jobs',
    queryParameters: {'status': 'Paid', 'page': 1, 'pageSize': 50},
  );
  final items = (response.data['data']['items'] as List?) ?? [];
  return items
      .map((e) => CompletedJobSummary.fromJson(e as Map<String, dynamic>))
      .toList();
});
