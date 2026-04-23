# mobile — Unified Flutter App (Customer + Provider)

## What is this?
The in-progress merge of `mobile-customer/` and `mobile-provider/` into a single
role-aware Flutter app. Still being built out phase-by-phase per
`migration-plan/`. Until the migration is complete, the two legacy apps remain
the production targets.

## Run
```bash
flutter pub get
flutter run
```
At the current phase the app launches into the role-picker `WelcomeScreen`
and can route to placeholder customer/provider home screens via mock login.
Phase 04 replaces the mock auth with real phone/OTP/password; Phase 05+
bring feature screens in.

## Identity
- Package ID / bundle ID: `com.khudmati.app` (both Android + iOS)
- Display name: "Khudmati"
- minSdk: 21 · iOS deployment target: 13.0
- Flutter `>=3.16.0` · Dart `>=3.2.0 <4.0.0`

## Architecture (Phase 03 state)
```
lib/
├── app/
│   ├── app.dart          # KhudmatiApp — MaterialApp.router wired to routerProvider
│   ├── router.dart       # routerProvider — GoRouter with role+token redirect guards
│   └── theme.dart        # AppTheme.light() — Cairo + Material 3
├── core/
│   ├── api/
│   │   └── api_client.dart          # Role-aware Dio + 401 refresh interceptor; apiClientProvider
│   ├── constants/
│   │   ├── app_config.dart          # backendHost, baseUrl, hubUrl
│   │   └── colors.dart              # AppColors — brand palette (brandBlue = #1B4F72, amber, etc.)
│   ├── l10n/
│   │   └── app_strings.dart         # S class — ~340 keys merged from both legacy apps
│   ├── providers/
│   │   ├── locale_provider.dart     # LocaleNotifier — shared_preferences-backed
│   │   └── role_provider.dart       # RoleNotifier — FlutterSecureStorage-backed (new)
│   ├── services/
│   │   ├── fcm_service.dart         # Role-aware device-token registration + listeners
│   │   └── signalr_service.dart     # HubConnection with JWT token factory + auto-reconnect
│   └── utils/
│       └── distance_utils.dart      # Haversine
├── features/
│   ├── auth/presentation/
│   │   ├── welcome_screen.dart          # Role picker — blue surface + customer/provider tiles
│   │   ├── login_placeholder.dart       # PLACEHOLDER — writes mock tokens (Phase 04 replaces)
│   │   └── register_placeholder.dart    # PLACEHOLDER — back-to-welcome (Phase 04 replaces)
│   ├── customer/
│   │   └── placeholder_home.dart        # PLACEHOLDER — logout button (Phase 06 replaces)
│   └── provider/
│       └── placeholder_home.dart        # PLACEHOLDER — logout button (Phase 07 replaces)
└── main.dart             # Bootstrap: Firebase (graceful), Stripe, persisted locale, ProviderScope
```

Real feature screens (Phase 05+) will land alongside the placeholder scaffolding.

## Routing (Phase 03)
- `routerProvider` (in `lib/app/router.dart`) returns a `GoRouter`. The redirect
  reads `access_token` and `user_role` directly from `FlutterSecureStorage` so
  it is correct on cold-start even before `roleProvider` finishes hydrating. A
  `ValueNotifier` wired to `ref.listen(roleProvider, ...)` pulses the router on
  login/logout transitions via `refreshListenable`.
- Routes: `/welcome` · `/login` · `/register` · `/customer/home` · `/provider/home`.
- Redirect matrix:
  - No token + `/welcome` → stay.
  - No token + (`/login` or `/register`) with role set → stay.
  - No token + anything else → `/welcome`.
  - Has token + role=customer but route ∉ `/customer/*` → `/customer/home`.
  - Has token + role=provider but route ∉ `/provider/*` → `/provider/home`.
  - Has token + role null → `/welcome` (edge case).

## Role awareness (new in the unified app)
- `roleProvider` is a `StateNotifierProvider<RoleNotifier, UserRole?>` that
  persists the current session's role (`customer` | `provider`) to
  `FlutterSecureStorage` under the key `user_role`. `null` means no session.
- `ApiClient` reads `roleProvider` inside its refresh interceptor to choose
  between `/auth/providers/refresh` and `/auth/customers/refresh`.
- `fcm_service` reads `roleProvider` to register the FCM token against
  `/providers/me/device-token` or `/customers/me/device-token`.
- `secureStorageProvider` is overridable in tests (see `test/widget_test.dart`
  for an in-memory fake pattern).

## Locale
- `localeProvider` — `StateNotifierProvider<LocaleNotifier, Locale>` defaulting
  to `Locale('en')`; persists changes via `shared_preferences` under key
  `locale_code`.
- `main.dart` reads the persisted value via `LocaleNotifier.loadPersisted()`
  and seeds the provider with a `ProviderScope` override before `runApp`.
- Change locale with `ref.read(localeProvider.notifier).setLocale(Locale('ar'))`.

## Strings merge policy
`app_strings.dart` is the union of the two legacy `S` classes. Customer wording
is canonical on collisions; the provider-side wording is exposed under a
`provider…` prefix when it differs. Current collisions:

| Canonical (customer)        | Provider variant              |
|-----------------------------|-------------------------------|
| `tagline`                   | `providerTagline`             |
| `registerTitle`             | `providerRegisterTitle`       |
| `fullNameTooShort`          | `providerFullNameTooShort`    |
| `statusInProgress`          | `providerStatusInProgress`    |
| `jobBeforePhotos`           | `providerJobBeforePhotos`     |
| `profileHelp`               | `providerProfileHelp`         |

When porting provider-side screens in Phase 07, swap the six collision sites to
the `provider…` variants so nothing regresses visually.

## API client
- Base URL via `AppConfig.baseUrl` → `https://api.khudmati.app/api`.
  To point at a local backend, change `AppConfig.backendHost`.
- Access token stored in `FlutterSecureStorage` under `access_token`; refresh
  token under `refresh_token` (unchanged keys from both legacy apps).
- Prefer `ref.watch(apiClientProvider)` over `ApiClient()` — the provider hands
  the interceptor a `Ref` so it can resolve the current role. Direct
  instantiation still works but the refresh will default to the customer path.

## FCM
- `initLocalNotifications()` must be called once during app boot (Phase 3 wires
  this into the router-bootstrap layer).
- `setupFcmListeners({ apiClient, router, ref })` wires foreground, opened-app,
  and initial-message handlers. The `_navigateFromMessage` fallback is a union
  of customer + provider payload types — Phase 08 replaces it with a proper
  role-aware notification handler.

## SignalR
- `signalRServiceProvider` exposes a single `HubConnection` against
  `AppConfig.hubUrl` → `/hubs/jobs`.
- JWT access-token factory reads `access_token` from secure storage; audience
  claim (`customer` vs `provider`) on the server decides group membership.
- Auto-reconnect enabled; `ref.onDispose` stops the connection when the
  provider is disposed.

## Dependencies pinned
`path_provider_android: 2.2.23` is pinned via `dependency_overrides` in
`pubspec.yaml` to avoid a flaky `jni 1.0.0` download from pub.dev. Remove
this override only if the pinned transitive dep can be fetched reliably in
your environment.

## Migration status
See `migration-plan/README.md` for the full 14-phase plan. Phase-by-phase
completion is tracked in git history on branch `feat/unified-app`.

| Phase | Title | Status |
|---|---|---|
| 00 | Prep & decisions | ✅ complete |
| 01 | Scaffold unified app | ✅ complete (commit `787fb7a`) |
| 02 | Port core / shared infrastructure | ✅ complete (commit `c6e3d55`) |
| 03 | Role selection + router skeleton | ✅ complete (commit `3a9123a`) |
| 04 | Shared auth screens (real phone/OTP/password) | ⏳ next |
| 05–13 | Features (customer flows, provider flows, payments, etc.) | ⏳ queued |

## Verification
- `flutter analyze` → 0 issues.
- `flutter test` → `test/widget_test.dart` exercises the role_provider
  read/write/clear cycle against an in-memory `FlutterSecureStorage` fake.
- Device/emulator smoke test (launch + locale persistence round-trip) pending
  manual verification per phase exit criteria.
