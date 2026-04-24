import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Phase 10 migration analytics. Fires `migration_opened_new_app` once per
/// install the first time the unified app successfully boots.
/// The flag is persisted in secure storage so reinstalls count as a new
/// migration (which is the desired behaviour — each install = one data
/// point in the funnel).
class MigrationAnalytics {
  static const _flagKey = 'migration_first_launch_logged';

  final FlutterSecureStorage _storage;

  MigrationAnalytics({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> logFirstLaunchIfNeeded({required bool firebaseReady}) async {
    try {
      final already = await _storage.read(key: _flagKey);
      if (already == 'true') return;

      if (firebaseReady) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'migration_opened_new_app',
          parameters: const {
            'source': 'unified_app_v1',
          },
        );
      } else {
        // Firebase not configured in this build (placeholder config files).
        // Still persist the flag so we don't spam debug logs every launch.
        debugPrint('[migration] Firebase not ready — analytics skipped.');
      }

      await _storage.write(key: _flagKey, value: 'true');
    } catch (e) {
      // Analytics is best-effort — never block app startup.
      debugPrint('[migration] logFirstLaunchIfNeeded failed: $e');
    }
  }
}
