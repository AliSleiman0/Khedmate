import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import '../constants/app_config.dart';
import '../logging/app_logger.dart';
import '../logging/redact.dart';
import '../network/connectivity_provider.dart';
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

    log.i('ApiClient', 'init', data: {
      'baseUrl': _baseUrl,
      'appPackage': AppConfig.appPackage,
      'appVersion': AppConfig.appVersion,
    });

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          log.d('ApiClient.onRequest', 'req start', data: {
            'method': options.method,
            'path': options.path,
            'hasAuth': token != null,
          });
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Backend may return 200 with `{"success": false, "error": "UPGRADE_REQUIRED"}`.
          // Hard-cutover live path (426) is caught in onError below.
          final upgrade = _readUpgradeRequired(response.data);
          if (upgrade != null) {
            log.w('ApiClient.onResponse', 'upgrade gate from 200', data: {
              'storeUrl': redactUrl(upgrade.storeUrl),
            });
            _ref?.read(upgradeRequiredProvider.notifier).state = upgrade;
          }
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Phase 10 — hard cutover gate. If the backend returns 426 or an
          // UPGRADE_REQUIRED payload, raise the app-wide flag and bail out
          // without attempting a refresh (refresh would hit the same gate).
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final upgrade = _readUpgradeRequired(error.response?.data);
          if (status == 426 || upgrade != null) {
            log.w('ApiClient.onError', 'upgrade gate from 4xx', data: {
              'status': status,
              'storeUrl': redactUrl(upgrade?.storeUrl),
            });
            _ref?.read(upgradeRequiredProvider.notifier).state =
                upgrade ?? const AppUpgradeRequired();
            handler.next(error);
            return;
          }

          // Connection-level failure (no DNS / no route / TLS handshake
          // timeout / captive portal). Belt-and-braces to the platform
          // connectivity stream — flips the `noInternetProvider` so the
          // global blocker takes over even when the OS reports the
          // interface as up.
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.unknown) {
            log.w('ApiClient.onError', 'connection error', data: {
              'type': error.type.name,
              'path': path,
            });
            _ref?.read(noInternetProvider.notifier).state = true;
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken == null) {
                log.w('ApiClient.onError',
                    'refresh skipped — no refresh token');
                await _clearTokens();
                _isRefreshing = false;
                handler.next(error);
                return;
              }

              final role = _ref?.read(roleProvider);
              final refreshPath = role == UserRole.provider
                  ? '/auth/providers/refresh'
                  : '/auth/customers/refresh';

              log.w('ApiClient.onError', 'refresh start', data: {
                'status': 401,
                'pathHint': role?.name ?? 'unknown',
              });

              final refreshResponse = await dio.post(
                refreshPath,
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

              log.i('ApiClient.onError', 'refresh ok', data: {
                'newToken': redactToken(newAccess),
              });

              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await dio.fetch(opts);
              _isRefreshing = false;
              handler.resolve(retryResponse);
            } catch (e, st) {
              log.e('ApiClient.onError', 'refresh failed',
                  error: e, stack: st);
              await _clearTokens();
              _isRefreshing = false;
              handler.next(error);
            }
          } else {
            log.d('ApiClient.onError', 'passthrough error', data: {
              'status': status,
              'path': path,
            });
            handler.next(error);
          }
        },
      ),
    );

    // TalkerDioLogger is added LAST so it sees the final outgoing request /
    // incoming response (after our auth header / upgrade-gate logic). Bodies
    // and auth headers are explicitly off — turning them on would leak OTPs,
    // passwords, and bearer tokens into the log buffer.
    dio.interceptors.add(
      TalkerDioLogger(
        talker: log.talker,
        settings: const TalkerDioLoggerSettings(
          printRequestData: false,
          printResponseData: false,
          printRequestHeaders: false,
          printResponseHeaders: false,
          printErrorMessage: true,
        ),
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
    log.i('ApiClient', 'tokens cleared');
  }
}

/// Preferred way to obtain an `ApiClient` — gives the refresh interceptor
/// access to `roleProvider` so it can route to the correct refresh endpoint.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref: ref);
});
