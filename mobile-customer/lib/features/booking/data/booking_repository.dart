import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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
    final response = await _client.dio.post('/bookings/jobs', data: {
      'categoryId': categoryId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'photoUrls': photoUrls ?? [],
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJob(String jobId) async {
    final response = await _client.dio.get('/bookings/jobs/$jobId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final response = await _client.dio.get('/jobs/$jobId/status');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<List<String>> uploadPhotos(String jobId, List<File> photos) async {
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(photo.path),
      ));
    }
    final response = await _client.dio.post(
      '/bookings/jobs/$jobId/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<String>.from(data['data'] as List);
    }
    return [];
  }

  Future<String> raiseDispute(String jobId, String complaint) async {
    final response = await _client.dio.post(
      '/bookings/jobs/$jobId/dispute',
      data: {'complaint': complaint},
    );
    final data = response.data as Map<String, dynamic>;
    return data['data']['disputeId'] as String;
  }
}
