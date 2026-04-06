import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  AuthRepository(this._dio, this._storage);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required List<String> serviceCategories,
  }) async {
    final res = await _dio.post('/auth/providers/register', data: {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'serviceCategories': serviceCategories,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/providers/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post('/auth/providers/login', data: {
      'phone': phone,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> resendOtp(String phone) async {
    await _dio.post('/auth/providers/resend-otp', data: {'phone': phone});
  }

  Future<Map<String, dynamic>?> refreshToken() async {
    if (_isRefreshing) return null;
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;
      final res = await _dio.post(
        '/auth/providers/refresh',
        data: {'refreshToken': refreshToken},
      );
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/providers/logout');
    } catch (_) {}
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');
}
