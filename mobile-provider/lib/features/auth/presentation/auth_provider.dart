import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Provider model
// ---------------------------------------------------------------------------
class ProviderUser {
  final String id;
  final String fullName;
  final String phone;

  ProviderUser({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory ProviderUser.fromJson(Map<String, dynamic> json) => ProviderUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Auth states
// ---------------------------------------------------------------------------
abstract class AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpPending extends AuthState {
  final String phone;
  AuthOtpPending(this.phone);
}

class AuthAuthenticated extends AuthState {
  final ProviderUser provider;
  AuthAuthenticated(this.provider);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Overridden in main.dart via ProviderScope overrides
  throw UnimplementedError('Override authRepositoryProvider in ProviderScope');
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getAccessToken();
    if (token == null) return AuthUnauthenticated();

    // Try to refresh to validate the stored token
    final refreshed = await repo.refreshToken();
    if (refreshed != null && refreshed['success'] == true) {
      final data = refreshed['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      // No provider object returned from refresh — mark authenticated with
      // minimal info; the jobs screen should fetch full profile separately.
      return AuthAuthenticated(ProviderUser(id: '', fullName: '', phone: ''));
    }
    return AuthUnauthenticated();
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required List<String> serviceCategories,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.register(
        fullName: fullName,
        phone: phone,
        password: password,
        serviceCategories: serviceCategories,
      );
      state = AsyncValue.data(AuthOtpPending(phone));
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.verifyOtp(phone: phone, otp: otp);
      final data = result['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      state = AsyncValue.data(
        AuthAuthenticated(
          ProviderUser.fromJson(data['provider'] as Map<String, dynamic>),
        ),
      );
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.login(phone: phone, password: password);
      final data = result['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      state = AsyncValue.data(
        AuthAuthenticated(
          ProviderUser.fromJson(data['provider'] as Map<String, dynamic>),
        ),
      );
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AsyncValue.data(AuthUnauthenticated());
  }

  Future<void> refreshToken() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.refreshToken();
    if (result == null || result['success'] != true) {
      state = AsyncValue.data(AuthUnauthenticated());
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
