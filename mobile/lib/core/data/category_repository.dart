import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../domain/service_category.dart';
import '../logging/app_logger.dart';

const _tag = 'CategoryRepo';

class CategoryRepository {
  final ApiClient _client;

  CategoryRepository(this._client);

  /// Fetches the active categories list from `/categories`. Anonymous endpoint
  /// — no auth header required, but the shared interceptor still sends
  /// `X-App-Package` / `X-App-Version` headers so the backend can identify
  /// this bundle.
  Future<List<ServiceCategory>> fetchActive() async {
    log.d(_tag, 'fetchActive start');
    final response = await _client.dio.get('/categories');
    final raw = response.data['data'] as List<dynamic>;
    final categories = raw
        .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    log.i(_tag, 'fetchActive ok', data: {'count': categories.length});
    return categories;
  }

  /// Resolves a single category by slug, even if inactive. Used to hydrate
  /// labels for historical jobs that reference a deactivated category.
  Future<ServiceCategory?> fetchBySlug(String slug) async {
    log.d(_tag, 'fetchBySlug start', data: {'slug': slug});
    try {
      final response = await _client.dio.get('/categories/$slug');
      final data = response.data['data'] as Map<String, dynamic>;
      return ServiceCategory.fromJson(data);
    } catch (e) {
      log.w(_tag, 'fetchBySlug failed', data: {'slug': slug});
      return null;
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(apiClientProvider));
});
