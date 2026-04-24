import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/role_provider.dart';

/// Role-aware wrapper around the auth HTTP surface. Every method branches on
/// `roleProvider` to hit `/auth/customers/*` or `/auth/providers/*`.
class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthRepository(this._dio, this._storage, this._ref);

  UserRole get _role => _ref.read(roleProvider) ?? UserRole.customer;
  String get _prefix =>
      _role == UserRole.provider ? '/auth/providers' : '/auth/customers';

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    List<String>? serviceCategories,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
    };
    if (_role == UserRole.provider) {
      body['serviceCategories'] = serviceCategories ?? const <String>[];
    }
    final res = await _dio.post('$_prefix/register', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post('$_prefix/login', data: {
      'phone': phone,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Customer-only email/password login helper. Providers don't support this —
  /// callers should check role before invoking.
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (_role == UserRole.provider) {
      throw UnsupportedError('Email login is not supported for providers');
    }
    final res = await _dio.post('$_prefix/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('$_prefix/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    final data = res.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>?;
    if (inner != null &&
        inner['accessToken'] != null &&
        inner['refreshToken'] != null) {
      await saveTokens(
        inner['accessToken'] as String,
        inner['refreshToken'] as String,
      );
    }
    return data;
  }

  Future<void> resendOtp(String phone) async {
    await _dio.post('$_prefix/resend-otp', data: {'phone': phone});
  }

  /// Customer-only — providers request a reset through admin.
  Future<void> forgotPassword({required String phone}) async {
    if (_role == UserRole.provider) {
      throw UnsupportedError('Password reset is customer-only');
    }
    await _dio.post('$_prefix/forgot-password', data: {'phone': phone});
  }

  /// Customer-only.
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    if (_role == UserRole.provider) {
      throw UnsupportedError('Password reset is customer-only');
    }
    await _dio.post('$_prefix/reset-password', data: {
      'phone': phone,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('$_prefix/logout');
    } catch (_) {
      // best-effort — still clear local state below
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: kProviderTierStorageKey);
    await _ref.read(roleProvider.notifier).clear();
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    final res = await _dio.get(path);
    return res.data as Map<String, dynamic>;
  }

  /// Role-aware profile update. Customers can set `email`; providers don't
  /// expose email on `/providers/me`, so we only send `fullName` for them.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    final body = <String, dynamic>{'fullName': fullName};
    if (_role == UserRole.customer) {
      body['email'] = email;
    }
    final res = await _dio.patch(path, data: body);
    return res.data as Map<String, dynamic>;
  }

  /// Required for Apple App Store review (guideline 5.1.1(v)) and Google Play
  /// Data Safety. Hits `DELETE /customers/me` or `DELETE /providers/me` on the
  /// backend. On success, clears local tokens + role so the next cold-start
  /// lands on `/welcome`. Backend endpoint must land before the first Apple
  /// submission — see `migration-plan/phase-12-implementation.md`.
  Future<void> deleteAccount() async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    await _dio.delete(path);
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: kProviderTierStorageKey);
    await _ref.read(roleProvider.notifier).clear();
  }

  // ---------------------------------------------------------------------------
  // Token helpers
  // ---------------------------------------------------------------------------

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(client.dio, storage, ref);
});
