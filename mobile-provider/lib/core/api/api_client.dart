import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

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
                // No refresh token — clear storage and pass error through.
                await _clearTokens();
                _isRefreshing = false;
                handler.next(error);
                return;
              }

              // Attempt the token refresh.
              final refreshResponse = await dio.post(
                '/providers/auth/refresh',
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

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
