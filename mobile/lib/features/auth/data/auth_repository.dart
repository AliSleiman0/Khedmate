import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/redact.dart';
import '../../../core/providers/role_provider.dart';

const _tag = 'AuthRepo';

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

  // Server error codes are surfaced as `{"error": "CODE"}` (plus an optional
  // `code` field on some endpoints). Pull whichever is present.
  String _errorCode(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        return (data['code'] as String?) ?? (data['error'] as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }

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
    log.d(_tag, 'register start', data: {
      'role': _role.name,
      'endpoint': '$_prefix/register',
      'phone': redactPhone(phone),
      'email': redactEmail(email),
    });
    final body = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
    };
    if (_role == UserRole.provider) {
      body['serviceCategories'] = serviceCategories ?? const <String>[];
    }
    try {
      final res = await _dio.post('$_prefix/register', data: body);
      log.i(_tag, 'register ok', data: {'role': _role.name});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'register failed', error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'register crashed', error: e, stack: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    log.d(_tag, 'login start', data: {
      'role': _role.name,
      'endpoint': '$_prefix/login',
      'phone': redactPhone(phone),
    });
    try {
      final res = await _dio.post('$_prefix/login', data: {
        'phone': phone,
        'password': password,
      });
      final data = (res.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>? ??
          const {};
      log.i(_tag, 'login ok', data: {
        'role': _role.name,
        'accessToken': redactToken(data['accessToken'] as String?),
        'userId': (data[_role == UserRole.provider ? 'provider' : 'customer']
                as Map<String, dynamic>?)?['id'],
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'login failed', error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'login crashed', error: e, stack: s);
      rethrow;
    }
  }

  /// Customer-only email/password login helper. Providers don't support this —
  /// callers should check role before invoking.
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (_role == UserRole.provider) {
      log.w(_tag, 'loginWithEmail blocked', data: {'role': _role.name});
      throw UnsupportedError('Email login is not supported for providers');
    }
    log.d(_tag, 'loginWithEmail start', data: {
      'endpoint': '$_prefix/login',
      'email': redactEmail(email),
    });
    try {
      final res = await _dio.post('$_prefix/login', data: {
        'email': email,
        'password': password,
      });
      final data = (res.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>? ??
          const {};
      log.i(_tag, 'loginWithEmail ok', data: {
        'accessToken': redactToken(data['accessToken'] as String?),
        'userId': (data['customer'] as Map<String, dynamic>?)?['id'],
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'loginWithEmail failed',
          error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'loginWithEmail crashed', error: e, stack: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    log.d(_tag, 'verifyOtp start', data: {
      'role': _role.name,
      'endpoint': '$_prefix/verify-otp',
      'phone': redactPhone(phone),
      'otp': redactOtp(otp),
    });
    try {
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
      log.i(_tag, 'verifyOtp ok', data: {
        'role': _role.name,
        'accessToken': redactToken(inner?['accessToken'] as String?),
      });
      return data;
    } on DioException catch (e) {
      log.e(_tag, 'verifyOtp failed', error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'verifyOtp crashed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> resendOtp(String phone) async {
    log.d(_tag, 'resendOtp start', data: {
      'role': _role.name,
      'endpoint': '$_prefix/resend-otp',
      'phone': redactPhone(phone),
    });
    try {
      await _dio.post('$_prefix/resend-otp', data: {'phone': phone});
      log.i(_tag, 'resendOtp ok');
    } on DioException catch (e) {
      log.e(_tag, 'resendOtp failed', error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'resendOtp crashed', error: e, stack: s);
      rethrow;
    }
  }

  /// Customer-only — providers request a reset through admin.
  Future<void> forgotPassword({required String phone}) async {
    if (_role == UserRole.provider) {
      log.w(_tag, 'forgotPassword blocked', data: {'role': _role.name});
      throw UnsupportedError('Password reset is customer-only');
    }
    log.d(_tag, 'forgotPassword start', data: {
      'endpoint': '$_prefix/forgot-password',
      'phone': redactPhone(phone),
    });
    try {
      await _dio.post('$_prefix/forgot-password', data: {'phone': phone});
      log.i(_tag, 'forgotPassword ok');
    } on DioException catch (e) {
      log.e(_tag, 'forgotPassword failed',
          error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'forgotPassword crashed', error: e, stack: s);
      rethrow;
    }
  }

  /// Customer-only.
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    if (_role == UserRole.provider) {
      log.w(_tag, 'resetPassword blocked', data: {'role': _role.name});
      throw UnsupportedError('Password reset is customer-only');
    }
    log.d(_tag, 'resetPassword start', data: {
      'endpoint': '$_prefix/reset-password',
      'phone': redactPhone(phone),
      'otp': redactOtp(otp),
    });
    try {
      await _dio.post('$_prefix/reset-password', data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
      log.i(_tag, 'resetPassword ok');
    } on DioException catch (e) {
      log.e(_tag, 'resetPassword failed',
          error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'resetPassword crashed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> logout() async {
    log.d(_tag, 'logout start',
        data: {'role': _role.name, 'endpoint': '$_prefix/logout'});
    try {
      await _dio.post('$_prefix/logout');
      log.i(_tag, 'logout ok');
    } catch (e) {
      // best-effort — still clear local state below
      log.w(_tag, 'logout server call failed (clearing local state anyway)',
          error: e);
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: kProviderTierStorageKey);
    await _ref.read(roleProvider.notifier).clear();
    log.i(_tag, 'tokens cleared');
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    log.d(_tag, 'fetchMe start',
        data: {'role': _role.name, 'endpoint': path});
    try {
      final res = await _dio.get(path);
      final data = (res.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>? ??
          const {};
      log.i(_tag, 'fetchMe ok',
          data: {'role': _role.name, 'userId': data['id']});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'fetchMe failed', error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'fetchMe crashed', error: e, stack: s);
      rethrow;
    }
  }

  /// Role-aware profile update. Customers can set `email`; providers don't
  /// expose email on `/providers/me`, so we only send `fullName` for them.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    log.d(_tag, 'updateProfile start', data: {
      'role': _role.name,
      'endpoint': path,
      'email': email == null ? null : redactEmail(email),
    });
    final body = <String, dynamic>{'fullName': fullName};
    if (_role == UserRole.customer) {
      body['email'] = email;
    }
    try {
      final res = await _dio.patch(path, data: body);
      log.i(_tag, 'updateProfile ok', data: {'role': _role.name});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log.e(_tag, 'updateProfile failed',
          error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'updateProfile crashed', error: e, stack: s);
      rethrow;
    }
  }

  /// Required for Apple App Store review (guideline 5.1.1(v)) and Google Play
  /// Data Safety. Hits `DELETE /customers/me` or `DELETE /providers/me` on the
  /// backend. On success, clears local tokens + role so the next cold-start
  /// lands on `/welcome`. Backend endpoint must land before the first Apple
  /// submission — see `migration-plan/phase-12-implementation.md`.
  Future<void> deleteAccount() async {
    final path = _role == UserRole.provider ? '/providers/me' : '/customers/me';
    log.d(_tag, 'deleteAccount start',
        data: {'role': _role.name, 'endpoint': path});
    try {
      await _dio.delete(path);
      log.i(_tag, 'deleteAccount ok', data: {'role': _role.name});
    } on DioException catch (e) {
      log.e(_tag, 'deleteAccount failed',
          error: e, data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, s) {
      log.e(_tag, 'deleteAccount crashed', error: e, stack: s);
      rethrow;
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: kProviderTierStorageKey);
    await _ref.read(roleProvider.notifier).clear();
    log.i(_tag, 'tokens cleared after delete');
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
