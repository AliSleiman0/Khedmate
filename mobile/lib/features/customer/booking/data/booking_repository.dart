import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';

const _tag = 'BookingRepo';

class BookingRepository {
  final ApiClient _client;

  BookingRepository(this._client);

  Future<Map<String, dynamic>> createJob({
    required String categoryId,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? photoUrls,
  }) async {
    log.d(_tag, 'createJob start', data: {
      'categoryId': categoryId,
      'descLen': description.length,
      'coords': redactLatLng(latitude, longitude),
      'photoCount': photoUrls?.length ?? 0,
    });
    try {
      final response = await _client.dio.post('/bookings/jobs', data: {
        'categoryId': categoryId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'photoUrls': photoUrls ?? [],
      });
      final data = response.data as Map<String, dynamic>;
      final inner = data['data'] as Map<String, dynamic>?;
      log.i(_tag, 'createJob ok', data: {'jobId': inner?['jobId']});
      return data;
    } on DioException catch (e) {
      log.e(_tag, 'createJob failed', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJob(String jobId) async {
    log.d(_tag, 'getJob start', data: {'jobId': jobId});
    final response = await _client.dio.get('/bookings/jobs/$jobId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final response = await _client.dio.get('/jobs/$jobId/status');
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<List<String>> uploadPhotos(String jobId, List<File> photos) async {
    log.d(_tag, 'uploadPhotos start',
        data: {'jobId': jobId, 'count': photos.length});
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(photo.path),
      ));
    }
    try {
      final response = await _client.dio.post(
        '/bookings/jobs/$jobId/photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final urls = List<String>.from(data['data'] as List);
        log.i(_tag, 'uploadPhotos ok',
            data: {'jobId': jobId, 'uploaded': urls.length});
        return urls;
      }
      log.w(_tag, 'uploadPhotos no urls', data: {'jobId': jobId});
      return [];
    } on DioException catch (e) {
      log.e(_tag, 'uploadPhotos failed', error: e, data: {'jobId': jobId});
      rethrow;
    }
  }

  Future<String> raiseDispute(String jobId, String complaint) async {
    log.d(_tag, 'raiseDispute start',
        data: {'jobId': jobId, 'reasonLen': complaint.length});
    try {
      final response = await _client.dio.post(
        '/bookings/jobs/$jobId/dispute',
        data: {'complaint': complaint},
      );
      final data = response.data as Map<String, dynamic>;
      final disputeId = data['data']['disputeId'] as String;
      log.i(_tag, 'raiseDispute ok',
          data: {'jobId': jobId, 'disputeId': disputeId});
      return disputeId;
    } on DioException catch (e) {
      log.e(_tag, 'raiseDispute failed', error: e, data: {'jobId': jobId});
      rethrow;
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});
