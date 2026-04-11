import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_repository.dart';
import '../../../core/api/api_client.dart';

// ---------------------------------------------------------------------------
// Customer model
// ---------------------------------------------------------------------------
class CustomerUser {
  final String id;
  final String fullName;
  final String phone;
  final String? email;

  CustomerUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) => CustomerUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
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
  final CustomerUser customer;
  AuthAuthenticated(this.customer);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final _authApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(_authApiClientProvider).dio, const FlutterSecureStorage());
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
      // Fetch the full profile to populate CustomerUser fields.
      try {
        final meResult = await repo.fetchMe();
        final meData = meResult['data'] as Map<String, dynamic>? ?? {};
        return AuthAuthenticated(CustomerUser.fromJson(meData));
      } catch (_) {
        return AuthAuthenticated(CustomerUser(id: '', fullName: '', phone: ''));
      }
    }
    return AuthUnauthenticated();
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
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
          CustomerUser.fromJson(data['customer'] as Map<String, dynamic>),
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
          CustomerUser.fromJson(data['customer'] as Map<String, dynamic>),
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

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    try {
      final result = await repo.loginWithEmail(email: email, password: password);
      final data = result['data'] as Map<String, dynamic>;
      await repo.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      state = AsyncValue.data(
        AuthAuthenticated(
          CustomerUser.fromJson(data['customer'] as Map<String, dynamic>),
        ),
      );
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
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
