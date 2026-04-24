import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

/// Phase 10 cutover gate. The backend flips
/// `Auth:ForceUpgradeForLegacyApps` on once the unified `com.khudmati.app`
/// is live in both stores; from that moment every legacy-provider request
/// comes back with `UPGRADE_REQUIRED`. The top-level `app.dart` listens to
/// this notifier and swaps the whole surface for a "Download new app" card.
final ValueNotifier<String?> upgradeRequiredNotifier =
    ValueNotifier<String?>(null);

class ApiClient {
  static const _baseUrl = AppConfig.baseUrl;
  final FlutterSecureStorage _storage;
  late final Dio dio;

  /// Whether a refresh is currently in flight — prevents infinite loops.
  bool _isRefreshing = false;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
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
          final storeUrl = _readUpgradeStoreUrl(response.data);
          if (storeUrl != null) {
            upgradeRequiredNotifier.value =
                storeUrl.isEmpty ? AppConfig.unifiedStoreUrl : storeUrl;
          }
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          final status = error.response?.statusCode;
          final storeUrl = _readUpgradeStoreUrl(error.response?.data);
          if (status == 426 || storeUrl != null) {
            upgradeRequiredNotifier.value = (storeUrl == null || storeUrl.isEmpty)
                ? AppConfig.unifiedStoreUrl
                : storeUrl;
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken == null) {
                // No refresh token — clear storage and pass error through.
                await _clearTokens();
                _isRefreshing = false;
                handler.next(error);
                return;
              }

              // Attempt the token refresh.
              final refreshResponse = await dio.post(
                '/auth/providers/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(
                  // Skip the interceptor for this request to avoid recursion.
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

              // Retry the original request with the new token.
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await dio.fetch(opts);
              _isRefreshing = false;
              handler.resolve(retryResponse);
            } catch (_) {
              // Refresh failed — clear tokens. The authNotifierProvider will
              // detect the missing token on its next build() call and redirect.
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

  /// Returns the store URL when the payload is a Phase 10 UPGRADE_REQUIRED
  /// response. Empty string = error code matched but no `storeUrl` supplied
  /// (caller falls back to `unifiedStoreUrl`). Null = not a migration gate
  /// response.
  static String? _readUpgradeStoreUrl(Object? data) {
    if (data is! Map) return null;
    if (data['error'] != 'UPGRADE_REQUIRED') return null;
    final inner = data['data'];
    final url = inner is Map ? inner['storeUrl'] as String? : null;
    return url ?? '';
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
