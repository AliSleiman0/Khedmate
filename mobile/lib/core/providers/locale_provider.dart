import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/app_logger.dart';

const _kLocaleStorageKey = 'locale_code';

/// Persists locale to `shared_preferences` on change and seeds from the same
/// key on boot. Defaults to English when no persisted value exists.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initial);

  Future<void> setLocale(Locale locale) async {
    log.i('LocaleProvider', 'set locale',
        data: {'code': locale.languageCode});
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleStorageKey, locale.languageCode);
  }

  /// Reads the persisted locale. Call this in `main()` before `runApp` and
  /// pass the result into `ProviderScope` as an override.
  static Future<Locale> loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleStorageKey);
    final locale = code == 'ar' ? const Locale('ar') : const Locale('en');
    log.d('LocaleProvider', 'load persisted',
        data: {'code': locale.languageCode});
    return locale;
  }
}

/// Watch for the current locale. Use `ref.read(localeProvider.notifier).setLocale(...)`
/// to change and persist.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(const Locale('en'));
});
