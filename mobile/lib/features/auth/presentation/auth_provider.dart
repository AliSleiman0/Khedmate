import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/role_provider.dart';
import '../data/auth_repository.dart';

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

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getAccessToken();
    if (token == null || token.isEmpty) {
      return const AuthUnauthenticated();
    }
    final role = ref.read(roleProvider);
    if (role == null) {
      // Token present but we don't know which role it belongs to — safest to
      // force a fresh login so the refresh endpoint can be chosen correctly.
      return const AuthUnauthenticated();
    }

    // ApiClient's interceptor handles refresh on 401 transparently. If
    // fetchMe throws after refresh, treat as unauthenticated.
    try {
      final result = await repo.fetchMe();
      final data = result['data'] as Map<String, dynamic>? ?? const {};
      return AuthAuthenticated(AppUser.fromJson(data), role);
    } catch (_) {
      return const AuthUnauthenticated();
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    List<String>? serviceCategories,
  }) async {
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
      state = AsyncValue.data(AuthOtpPending(phone));
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final role = ref.read(roleProvider) ?? UserRole.customer;
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
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final role = ref.read(roleProvider) ?? UserRole.customer;
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
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final role = ref.read(roleProvider) ?? UserRole.customer;
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
      state = AsyncValue.data(AuthAuthenticated(user, role));
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.deleteAccount();
    state = const AsyncValue.data(AuthUnauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
