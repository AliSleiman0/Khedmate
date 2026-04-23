import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';
import '../providers/role_provider.dart';

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
      headers: {'Content-Type': 'application/json'},
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
        onError: (DioException error, handler) async {
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
