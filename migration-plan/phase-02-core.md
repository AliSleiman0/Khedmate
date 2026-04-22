# Phase 02 — Port Core / Shared Infrastructure

## Goal
Move the 100%-shared plumbing (theme, l10n, API client, SignalR, FCM, locale, role provider) into the new `mobile/` app so later feature phases have stable foundations to build on.

## Why this phase
~70% of both apps is already identical infrastructure. Porting it once, role-aware from the start, means Phase 4+ can import and use these as-is without retrofitting.

## Pre-requisites
- Phase 01 complete (scaffold builds)
- On branch `feat/unified-app`

## Scope

### 1. Port `lib/core/constants/colors.dart`
**Source (canonical):** `mobile-customer/lib/core/constants/colors.dart`

Reason: the customer app has the corrected `brandBlue = #1B4F72` plus the extended warm palette (brandBlueDeep, amber variants, cream, ink, line). Provider app still has the buggy `#3B1704`.

Copy verbatim to `mobile/lib/core/constants/colors.dart`.

### 2. Port `lib/core/l10n/app_strings.dart`
**Sources:**
- `mobile-customer/lib/core/l10n/app_strings.dart` (263 keys)
- `mobile-provider/lib/core/l10n/app_strings.dart` (267 keys)

**Merge strategy:**
- ~190 shared keys: take whichever wording is better (prefer customer's)
- 73 customer-unique keys: copy in as-is
- 77 provider-unique keys: copy in as-is
- On key collisions (same name, different string): keep customer's, and add a provider-prefixed version (`providerJobs` etc.) — fix call sites when porting in Phase 7

Output: `mobile/lib/core/l10n/app_strings.dart` with ~340 keys total.

### 3. Port `lib/core/providers/locale_provider.dart`
Copy from either app (identical). Add persistence:
- On change, write `locale_code` (`en` / `ar`) to `shared_preferences`
- On app boot (`main.dart`), read `locale_code` and seed the provider before `runApp`

Output: `mobile/lib/core/providers/locale_provider.dart`

### 4. Create `lib/core/providers/role_provider.dart` (NEW)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum UserRole { customer, provider }

const _kRoleStorageKey = 'user_role';

class RoleNotifier extends StateNotifier<UserRole?> {
  final FlutterSecureStorage _storage;
  RoleNotifier(this._storage) : super(null) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final raw = await _storage.read(key: _kRoleStorageKey);
    if (raw == 'customer') state = UserRole.customer;
    if (raw == 'provider') state = UserRole.provider;
  }

  Future<void> setRole(UserRole role) async {
    state = role;
    await _storage.write(key: _kRoleStorageKey, value: role.name);
  }

  Future<void> clear() async {
    state = null;
    await _storage.delete(key: _kRoleStorageKey);
  }
}

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

final roleProvider = StateNotifierProvider<RoleNotifier, UserRole?>((ref) {
  return RoleNotifier(ref.read(secureStorageProvider));
});
```

### 5. Port `lib/core/api/api_client.dart` — make role-aware
**Source:** `mobile-customer/lib/core/api/api_client.dart`

Change the refresh-token interceptor to pick the endpoint based on current role:
```dart
final role = ref.read(roleProvider);
final path = role == UserRole.provider
    ? '/auth/providers/refresh'
    : '/auth/customers/refresh';
```

Base URL remains `https://api.khudmati.app/api`. Secure storage keys remain `access_token` and `refresh_token`.

### 6. Port `lib/core/services/signalr_service.dart`
**Source:** either app (identical). Copy verbatim.

Hub path `/hubs/jobs` unchanged. JWT access token factory still reads `access_token` from secure storage. Auto-reconnect logic unchanged.

### 7. Port `lib/core/services/fcm_service.dart` — make role-aware
**Source:** `mobile-provider/lib/core/services/fcm_service.dart` (has more complete deep-link routing)

Change device-token registration endpoint to pick by role:
```dart
final role = ref.read(roleProvider);
final path = role == UserRole.provider
    ? '/providers/me/device-token'
    : '/customers/me/device-token';
```

Leave notification-handling logic alone — the notification handler in Phase 8 will re-route by role.

### 8. Port `lib/core/utils/distance_utils.dart`
**Source:** `mobile-customer/lib/core/utils/distance_utils.dart` (Haversine)

Copy verbatim.

### 9. Port theme
**Source:** either app (near-identical Cairo + Material 3)

Output: `mobile/lib/app/theme.dart`

### 10. Create `main.dart` entry point
Minimal bootstrap:
- `WidgetsFlutterBinding.ensureInitialized()`
- Firebase.initializeApp() (fails gracefully if not configured yet — Phase 9)
- Stripe.publishableKey (use test key for now — env-gate in Phase 9)
- Read persisted locale from `shared_preferences`
- Wrap in `ProviderScope` with locale override
- `runApp(KhudmatiApp())`

`KhudmatiApp` widget — `MaterialApp.router` with empty router config (filled in Phase 3).

## Files to create
- `mobile/lib/app/app.dart`
- `mobile/lib/app/theme.dart`
- `mobile/lib/core/constants/colors.dart`
- `mobile/lib/core/constants/app_config.dart`
- `mobile/lib/core/l10n/app_strings.dart`
- `mobile/lib/core/providers/locale_provider.dart`
- `mobile/lib/core/providers/role_provider.dart` **(new)**
- `mobile/lib/core/api/api_client.dart`
- `mobile/lib/core/services/signalr_service.dart`
- `mobile/lib/core/services/fcm_service.dart`
- `mobile/lib/core/utils/distance_utils.dart`
- `mobile/lib/main.dart`

## Files to reference (read-only)
- `mobile-customer/lib/core/**`
- `mobile-provider/lib/core/**`

## Verification
- `flutter analyze` clean (0 errors)
- `flutter run` launches app (shows empty `MaterialApp` — blank screen is expected at this stage)
- Locale provider persists across app restarts (manual test: call `setLocale(Locale('ar'))`, kill app, relaunch — should still be AR)
- Role provider initializes to `null` on fresh install

## Exit criteria
- [ ] All files listed above exist under `mobile/lib/core/`
- [ ] `flutter analyze` clean
- [ ] App launches without crash
- [ ] Locale persistence verified
- [ ] Role provider compiles and can be read/written from tests
- [ ] Commit pushed: `feat(mobile): port shared core infrastructure`

## Rollback
- Core folder is additive — revert the commit. No data migration needed.
