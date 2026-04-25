import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../domain/service_category.dart';
import '../logging/app_logger.dart';

const _tag = 'CategoriesProvider';

/// Cold-start fetch of the active service categories. Mirrors the
/// `analyticsProvider` keepAlive shape — 5 minutes of cache, then auto-dispose.
/// Pull-to-refresh callers should `ref.invalidate(categoriesProvider)`.
final categoriesProvider =
    FutureProvider.autoDispose<List<ServiceCategory>>((ref) async {
  log.d(_tag, 'load start');
  final repo = ref.read(categoryRepositoryProvider);

  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  try {
    final categories = await repo.fetchActive();
    log.i(_tag, 'load ok', data: {'count': categories.length});
    return categories;
  } catch (e, st) {
    log.e(_tag, 'load failed', error: e, stack: st);
    rethrow;
  }
});

/// Returns the active category matching [slug] from the cached list, or null
/// when the slug doesn't exist (or the category is inactive — inactive
/// categories must be fetched explicitly via [CategoryRepository.fetchBySlug]).
final categoryBySlugProvider =
    Provider.family.autoDispose<ServiceCategory?, String>((ref, slug) {
  final list = ref.watch(categoriesProvider).valueOrNull;
  if (list == null) return null;
  for (final c in list) {
    if (c.slug == slug) return c;
  }
  return null;
});
