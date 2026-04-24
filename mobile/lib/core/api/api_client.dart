import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';
import '../providers/role_provider.dart';

/// Thrown by the response interceptor when the backend returns
/// `{"success": false, "error": "UPGRADE_REQUIRED", ...}` (HTTP 426 or 200).
/// The router listens for this via [upgradeRequiredProvider] and swaps the
/// whole surface for a full-screen upgrade card.
class AppUpgradeRequired implements Exception {
  final String? storeUrl;
  const AppUpgradeRequired({this.storeUrl});
  @override
  String toString() => 'AppUpgradeRequired(storeUrl: $storeUrl)';
}

/// App-wide flag flipped by the [ApiClient] when any request comes back with
/// an `UPGRADE_REQUIRED` error. Screens / router can watch it to render the
/// migration screen.
final upgradeRequiredProvider = StateProvider<AppUpgradeRequired?>((_) => null);

/// Role-aware HTTP client. The refresh interceptor picks the correct refresh
/// endpoint based on the current `roleProvider` value (customer or provider).
class ApiClient {
  static const _baseUrl = AppConfig.baseUrl;
  final FlutterSecureStorage _storage;
  final Ref? _ref;
  late final Dio dio;

  /// Whether a refresh is currently in flight — prevents infinite loops.
  bool _isRefreshing = false;

  ApiClient({FlutterSecureStorage? storage, Ref? ref})
      : _storage = storage ?? const FlutterSecureStorage(),
        _ref = ref {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        // Phase 10 — let backend distinguish this bundle from the legacy
        // `com.khudmati.customer` / `com.khudmati.provider` installs.
        'X-App-Package': AppConfig.appPackage,
        'X-App-Version': AppConfig.appVersion,
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Backend may return 200 with `{"success": false, "error": "UPGRADE_REQUIRED"}`.
          // Hard-cutover live path (426) is caught in onError below.
          final upgrade = _readUpgradeRequired(response.data);
          if (upgrade != null) {
            _ref?.read(upgradeRequiredProvider.notifier).state = upgrade;
          }
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Phase 10 — hard cutover gate. If the backend returns 426 or an
          // UPGRADE_REQUIRED payload, raise the app-wide flag and bail out
          // without attempting a refresh (refresh would hit the same gate).
          final status = error.response?.statusCode;
          final upgrade = _readUpgradeRequired(error.response?.data);
          if (status == 426 || upgrade != null) {
            _ref?.read(upgradeRequiredProvider.notifier).state =
                upgrade ?? const AppUpgradeRequired();
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken == null) {
                await _clearTokens();
                _isRefreshing = false;
                handler.next(error);
                return;
              }

              final role = _ref?.read(roleProvider);
              final path = role == UserRole.provider
                  ? '/auth/providers/refresh'
                  : '/auth/customers/refresh';

              final refreshResponse = await dio.post(
                path,
                data: {'refreshToken': refreshToken},
                options: Options(
                  extra: {'skipInterceptor': true},
                  headers: {'Authorization': null},
                ),
              );

              final data =
                  (refreshResponse.data as Map<String, dynamic>)['data']
                      as Map<String, dynamic>;
              final newAccess = data['accessToken'] as String;
              final newRefresh = data['refreshToken'] as String;

              await _storage.write(key: 'access_token', value: newAccess);
              await _storage.write(key: 'refresh_token', value: newRefresh);

              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await dio.fetch(opts);
              _isRefreshing = false;
              handler.resolve(retryResponse);
            } catch (_) {
              await _clearTokens();
              _isRefreshing = false;
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  /// Parse `{"success": false, "error": "UPGRADE_REQUIRED", "data": {"storeUrl": "..."}}`
  /// out of a payload (200 or 4xx). Returns null when the payload is not a
  /// migration gate response.
  static AppUpgradeRequired? _readUpgradeRequired(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error != 'UPGRADE_REQUIRED') return null;
    final inner = data['data'];
    final storeUrl = inner is Map ? inner['storeUrl'] as String? : null;
    return AppUpgradeRequired(storeUrl: storeUrl);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

/// Preferred way to obtain an `ApiClient` — gives the refresh interceptor
/// access to `roleProvider` so it can route to the correct refresh endpoint.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref: ref);
});
