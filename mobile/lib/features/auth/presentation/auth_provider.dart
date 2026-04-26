import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/role_provider.dart';
import '../data/auth_repository.dart';

const _tag = 'AuthNotifier';

/// Unified user model. `email` is populated for customers; providers don't
/// expose an email via `/providers/me`.
class AppUser {
  final String id;
  final String fullName;
  final String phone;
  final String? email;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
      );

  static const empty = AppUser(id: '', fullName: '', phone: '');
}

// ---------------------------------------------------------------------------
// Auth state union
// ---------------------------------------------------------------------------
abstract class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpPending extends AuthState {
  final String phone;
  const AuthOtpPending(this.phone);
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  final UserRole role;
  const AuthAuthenticated(this.user, this.role);
}

String _errorCode(Object err) {
  if (err is DioException) {
    try {
      final data = err.response?.data;
      if (data is Map) {
        return (data['code'] as String?) ?? (data['error'] as String?) ?? '';
      }
    } catch (_) {}
  }
  return '';
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getAccessToken();
    final role = ref.read(roleProvider);
    log.d(_tag, 'build', data: {
      'hasToken': token != null && token.isNotEmpty,
      'role': role?.name,
    });
    if (token == null || token.isEmpty) {
      log.i(_tag, 'no session');
      return const AuthUnauthenticated();
    }
    if (role == null) {
      log.w(_tag, 'token without role — forcing re-auth');
      return const AuthUnauthenticated();
    }

    log.i(_tag, 'fetchMe start');
    try {
      final result = await repo.fetchMe();
      final data = result['data'] as Map<String, dynamic>? ?? const {};
      final user = AppUser.fromJson(data);
      log.i(_tag, 'fetchMe ok', data: {'role': role.name, 'userId': user.id});
      return AuthAuthenticated(user, role);
    } on DioException catch (e) {
      // Network-level failures (offline, DNS, captive portal, server
      // unreachable) must NOT clear the session — tokens are still on
      // disk and the no-internet blocker will surface the issue. Only
      // a hard 401/403 from the backend means the session is gone.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        log.w(_tag, 'fetchMe rejected — clearing session',
            data: {'status': status});
        return const AuthUnauthenticated();
      }
      log.w(_tag, 'fetchMe failed — keeping session', data: {
        'status': status,
        'type': e.type.name,
      });
      return AuthAuthenticated(AppUser.empty, role);
    } catch (e) {
      log.w(_tag, 'fetchMe crashed — keeping session', error: e);
      return AuthAuthenticated(AppUser.empty, role);
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    List<String>? serviceCategories,
  }) async {
    log.d(_tag, 'register start', data: {'role': ref.read(roleProvider)?.name});
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        serviceCategories: serviceCategories,
      );
      log.i(_tag, 'register ok — otp pending');
      state = AsyncValue.data(AuthOtpPending(phone));
    } on DioException catch (e, st) {
      log.w(_tag, 'register failed', data: {'code': _errorCode(e)});
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final role = ref.read(roleProvider) ?? UserRole.customer;
    log.d(_tag, 'verifyOtp start', data: {'role': role.name});
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.verifyOtp(phone: phone, otp: otp);
      final data = result['data'] as Map<String, dynamic>;
      // verifyOtp in repo already saves tokens if present; handle the case
      // where the payload differs by saving defensively here too.
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        await repo.saveTokens(accessToken, refreshToken);
      }

      final userJson = (role == UserRole.provider
              ? data['provider']
              : data['customer']) as Map<String, dynamic>?;
      final user = userJson != null
          ? AppUser.fromJson(userJson)
          : AppUser.empty;
      log.i(_tag, 'verifyOtp ok',
          data: {'role': role.name, 'userId': user.id});
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      log.w(_tag, 'verifyOtp failed', data: {'code': _errorCode(e)});
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      log.e(_tag, 'verifyOtp crashed', error: e, stack: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final role = ref.read(roleProvider) ?? UserRole.customer;
    log.d(_tag, 'login start', data: {'role': role.name});
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.login(phone: phone, password: password);
      final data = result['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      final userJson = (role == UserRole.provider
              ? data['provider']
              : data['customer']) as Map<String, dynamic>?;
      final user = userJson != null
          ? AppUser.fromJson(userJson)
          : AppUser.empty;
      log.i(_tag, 'login ok', data: {'role': role.name, 'userId': user.id});
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      log.w(_tag, 'login failed', data: {'code': _errorCode(e)});
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final role = ref.read(roleProvider) ?? UserRole.customer;
    log.d(_tag, 'loginWithEmail start', data: {'role': role.name});
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.loginWithEmail(email: email, password: password);
      final data = result['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      final userJson = data['customer'] as Map<String, dynamic>?;
      final user = userJson != null
          ? AppUser.fromJson(userJson)
          : AppUser.empty;
      log.i(_tag, 'loginWithEmail ok',
          data: {'role': role.name, 'userId': user.id});
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      log.w(_tag, 'loginWithEmail failed', data: {'code': _errorCode(e)});
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    log.d(_tag, 'logout start');
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    log.i(_tag, 'logout ok');
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    log.d(_tag, 'deleteAccount start');
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.deleteAccount();
      log.i(_tag, 'deleteAccount ok');
      state = const AsyncValue.data(AuthUnauthenticated());
    } on DioException catch (e) {
      log.w(_tag, 'deleteAccount failed', data: {'code': _errorCode(e)});
      rethrow;
    } catch (e, st) {
      log.e(_tag, 'deleteAccount crashed', error: e, stack: st);
      rethrow;
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
