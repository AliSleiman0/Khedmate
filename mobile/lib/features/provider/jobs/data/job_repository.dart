import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';

const _tag = 'JobRepo';

class JobSummary {
  final String id;
  final String referenceNumber;
  final String categoryId;
  final String categoryName;
  final double distanceKm;
  final String district;
  final int secondsRemaining;
  final DateTime postedAt;
  final bool hasPhotos;

  // For SignalR-pushed jobs (distance computed client-side)
  final double? latitude;
  final double? longitude;

  JobSummary({
    required this.id,
    required this.referenceNumber,
    required this.categoryId,
    required this.categoryName,
    required this.distanceKm,
    required this.district,
    required this.secondsRemaining,
    required this.postedAt,
    required this.hasPhotos,
    this.latitude,
    this.longitude,
  });

  factory JobSummary.fromJson(Map<String, dynamic> json) => JobSummary(
        id: (json['jobId'] ?? json['id'] ?? '').toString(),
        referenceNumber: json['referenceNumber'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        district: json['district'] as String? ?? '',
        secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 0,
        postedAt: json['postedAt'] != null
            ? DateTime.parse(json['postedAt'] as String)
            : DateTime.now(),
        hasPhotos: json['hasPhotos'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class JobDetail {
  final String id;
  final String referenceNumber;
  final String categoryId;
  final String categoryName;
  final String description;
  final double latitude;
  final double longitude;
  final String district;
  final double distanceKm;
  final List<String> beforePhotoUrls;
  final List<String> afterPhotoUrls;
  final int secondsRemaining;
  final DateTime postedAt;
  final String status;
  final String? customerFirstName;
  final String? customerPhone;
  final DateTime? paidAt;

  JobDetail({
    required this.id,
    required this.referenceNumber,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.distanceKm,
    required this.beforePhotoUrls,
    required this.afterPhotoUrls,
    required this.secondsRemaining,
    required this.postedAt,
    required this.status,
    this.customerFirstName,
    this.customerPhone,
    this.paidAt,
  });

  JobDetail copyWith({String? status}) => JobDetail(
        id: id,
        referenceNumber: referenceNumber,
        categoryId: categoryId,
        categoryName: categoryName,
        description: description,
        latitude: latitude,
        longitude: longitude,
        district: district,
        distanceKm: distanceKm,
        beforePhotoUrls: beforePhotoUrls,
        afterPhotoUrls: afterPhotoUrls,
        secondsRemaining: secondsRemaining,
        postedAt: postedAt,
        status: status ?? this.status,
        customerFirstName: customerFirstName,
        customerPhone: customerPhone,
        paidAt: paidAt,
      );

  factory JobDetail.fromJson(Map<String, dynamic> json) => JobDetail(
        id: (json['jobId'] ?? json['id'] ?? '').toString(),
        referenceNumber: json['referenceNumber'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        district: json['district'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        beforePhotoUrls: (json['beforePhotoUrls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        afterPhotoUrls: (json['afterPhotoUrls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 0,
        postedAt: json['postedAt'] != null
            ? DateTime.parse(json['postedAt'] as String)
            : DateTime.now(),
        status: json['status'] as String? ?? 'Pending',
        customerFirstName: json['customerFirstName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'] as String)
            : null,
      );
}

class JobRepository {
  final ApiClient _client;

  JobRepository(this._client);

  Future<List<JobSummary>> getAvailableJobs(
      {int page = 1, int pageSize = 20}) async {
    log.d(_tag, 'getAvailableJobs start',
        data: {'page': page, 'pageSize': pageSize});
    try {
      final response = await _client.dio.get(
        '/providers/jobs/available',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['data']['items'] as List);
      final list = items
          .map((e) => JobSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      log.i(_tag, 'getAvailableJobs ok', data: {'count': list.length});
      return list;
    } on DioException catch (e) {
      log.e(_tag, 'getAvailableJobs failed', error: e);
      rethrow;
    }
  }

  Future<JobDetail> getJobById(String jobId) async {
    log.d(_tag, 'getJobById start', data: {'jobId': jobId});
    final response = await _client.dio.get('/providers/jobs/$jobId');
    final data = response.data as Map<String, dynamic>;
    return JobDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> respondToJob(String jobId, String action) async {
    log.d(_tag, 'respondToJob start',
        data: {'jobId': jobId, 'action': action});
    try {
      await _client.dio.post(
        '/providers/jobs/$jobId/respond',
        data: {'action': action},
      );
      log.i(_tag, 'respondToJob ok',
          data: {'jobId': jobId, 'action': action});
    } on DioException catch (e) {
      log.e(_tag, 'respondToJob failed',
          error: e, data: {'jobId': jobId, 'action': action});
      rethrow;
    }
  }

  Future<List<JobDetail>> getActiveJobs() async {
    log.d(_tag, 'getActiveJobs start');
    final response = await _client.dio.get('/providers/jobs/active');
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List);
    final list = items
        .map((e) => JobDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    log.i(_tag, 'getActiveJobs ok', data: {'count': list.length});
    return list;
  }

  Future<JobDetail> advanceJobStatus(String jobId) async {
    log.d(_tag, 'advanceJobStatus start', data: {'jobId': jobId});
    try {
      await _client.dio.post('/providers/jobs/$jobId/advance');
      // The advance endpoint returns AdvanceJobStatusResultDto, not a full
      // JobDetail. Re-fetch the job so the screen gets the full updated detail.
      final detail = await getJobById(jobId);
      log.i(_tag, 'advanceJobStatus ok',
          data: {'jobId': jobId, 'status': detail.status});
      return detail;
    } on DioException catch (e) {
      log.e(_tag, 'advanceJobStatus failed',
          error: e, data: {'jobId': jobId});
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    await _client.dio.post('/providers/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> sendLocationForJob(
      String jobId, double latitude, double longitude) async {
    log.v(_tag, 'sendLocationForJob', data: {
      'jobId': jobId,
      'coords': redactLatLng(latitude, longitude),
    });
    await _client.dio.post('/tracking/jobs/$jobId/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<String>> uploadAfterPhotos(
      String jobId, List<XFile> photos) async {
    log.d(_tag, 'uploadAfterPhotos start',
        data: {'jobId': jobId, 'count': photos.length});
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(photo.path, filename: photo.name),
      ));
    }
    try {
      final response = await _client.dio.post(
        '/providers/jobs/$jobId/after-photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data as Map<String, dynamic>;
      final urls = (data['data'] as List).map((e) => e.toString()).toList();
      log.i(_tag, 'uploadAfterPhotos ok',
          data: {'jobId': jobId, 'uploaded': urls.length});
      return urls;
    } on DioException catch (e) {
      log.e(_tag, 'uploadAfterPhotos failed',
          error: e, data: {'jobId': jobId});
      rethrow;
    }
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(ref.watch(apiClientProvider));
});
