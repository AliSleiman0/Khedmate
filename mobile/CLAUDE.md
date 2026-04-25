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
At the current phase the app launches into the role-picker `WelcomeScreen`,
runs real phone/OTP/password auth against the backend, and routes each role
into its own `StatefulShellRoute` scaffold. Customers land on a 4-tab shell
(Home / History / Notifications / Profile) with the Direction-C home
redesign + amber FAB booking flow. Providers land on a 4-tab shell
(Jobs / Earnings / Notifications / Profile) with the full job feed,
onboarding hub (ID upload + skill test), active job / navigation / after-
photo flow, Stripe Connect payout status, Power Provider subscription
(Stripe PaymentSheet), and analytics dashboard (`fl_chart`). Phase 05
added shared features (chat, notifications, profile, rating); Phase 06
ported the full customer stack; Phase 07 ported the full provider stack.
Phase 08 consolidated routing into one role-aware `GoRouter`, moved
chat/notifications/profile under `/customer/*` + `/provider/*`
namespaces (removed the Phase-5 top-level shims), added provider-tier
gating on cold start, and introduced a single `NotificationHandler`
that dispatches both FCM taps and `khudmati://` deep links to the right
role-scoped route. Phase 09 finalised platform config for release
builds — Android permissions + queries, iOS usage descriptions +
background modes, localised display name (`Khudmati` / `خدمتي`),
ProGuard/R8 rules for Stripe + SignalR + Firebase + Play Core,
`--dart-define STRIPE_PUBLISHABLE_KEY` gating, and placeholder config
for `flutter_launcher_icons` / `flutter_native_splash`. Firebase config
files (`google-services.json`, `GoogleService-Info.plist`) are
git-ignored with `.example` placeholders checked in. Phase 10 shipped
the hard-cutover gate for existing legacy users — `X-App-Package` +
`X-App-Version` headers on every request, a typed `AppUpgradeRequired`
exception raised by the Dio response/error interceptor when the
backend returns 426 or `{"error":"UPGRADE_REQUIRED"}`, a root
`UpgradeRequiredScreen` swapped in via `upgradeRequiredProvider`, and
a one-shot `migration_opened_new_app` Firebase Analytics event on
first launch. Both legacy apps were patched with the same gate so
the cutover can be flipped on atomically from the backend when the
unified app reaches production.

## Identity
- Package ID / bundle ID: `com.khudmati.app` (both Android + iOS)
- Display name: "Khudmati" (EN) / "خدمتي" (AR) — localised via
  `values/strings.xml` + `values-ar/strings.xml` on Android and
  `en.lproj/InfoPlist.strings` + `ar.lproj/InfoPlist.strings` on iOS.
  The Android manifest references `@string/app_name`; iOS reads from
  `CFBundleDisplayName`.
- minSdk: 21 · iOS deployment target: 13.0
- Flutter `>=3.16.0` · Dart `>=3.2.0 <4.0.0`

## Architecture (Phase 05 state)
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
│   ├── logging/                     # ← Logging Phase 01 — Talker-backed AppLogger
│   │   ├── app_logger.dart          # log.v/d/i/w/e/c — singleton wrapper around Talker
│   │   ├── app_logger_providers.dart # loggerProvider + talkerProvider (Riverpod)
│   │   ├── log_viewer_screen.dart   # /debug/logs — TalkerScreen, kDebugMode-only
│   │   └── redact.dart              # redactPhone / redactEmail / redactToken / redactLatLng / redactOtp
│   ├── providers/
│   │   ├── locale_provider.dart     # LocaleNotifier — shared_preferences-backed
│   │   └── role_provider.dart       # RoleNotifier — FlutterSecureStorage-backed (new)
│   ├── services/
│   │   ├── fcm_service.dart              # Role-aware device-token registration + FCM listeners (delegates taps to NotificationHandler)
│   │   ├── notification_handler.dart     # ← Phase 08 — FCM taps + khudmati:// deep links → role-aware routes
│   │   └── signalr_service.dart          # HubConnection with JWT token factory + auto-reconnect
│   └── utils/
│       └── distance_utils.dart      # Haversine
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart      # Role-aware; _prefix → /auth/customers vs /auth/providers; updateProfile()
│   │   └── presentation/
│   │       ├── welcome_screen.dart       # Role picker — blue surface + customer/provider tiles
│   │       ├── auth_provider.dart        # AuthNotifier (AsyncNotifier<AuthState>) + AppUser model
│   │       ├── login_page.dart           # Phone/email toggle customer-only; provider = phone only
│   │       ├── register_screen.dart      # Service-category multi-select shown only when role=provider
│   │       ├── otp_screen.dart           # Pinput OTP; customer-only referral code bottom sheet
│   │       ├── forgot_password_screen.dart  # Customer-only (router bounces providers back)
│   │       └── reset_password_screen.dart   # Customer-only
│   ├── shared/                              # ← Phase 05 — role-agnostic feature surfaces
│   │   ├── chat/
│   │   │   ├── data/chat_repository.dart        # GET/POST /chat/jobs/{id}/messages, markAsRead, unreadCount
│   │   │   ├── presentation/
│   │   │   │   ├── chat_provider.dart           # ChatNotifier family + SignalR NewChatMessage
│   │   │   │   └── chat_screen.dart             # Unified; selfSenderType derived from roleProvider
│   │   │   └── widgets/
│   │   │       ├── chat_input_bar.dart          # Reused from legacy provider app
│   │   │       └── chat_message_list.dart       # ChatMessage model + list + date separators
│   │   ├── notifications/
│   │   │   ├── data/notification_repository.dart # GET /notifications?role=<>; markRead
│   │   │   ├── domain/notification_model.dart    # AppNotification — adds type + data fields
│   │   │   └── presentation/
│   │   │       ├── notifications_provider.dart   # AsyncNotifier<List<AppNotification>> + unread/hasMore
│   │   │       └── notifications_screen.dart     # List + role-aware handleNotificationTap(...)
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       ├── profile_page.dart             # Shell (header + logout), delegates to tile widgets
│   │   │       ├── profile_tiles_customer.dart   # Edit / Addresses (Coming Soon) / Payment (Coming Soon) / Referral / Language / Notifications / Help
│   │   │       ├── profile_tiles_provider.dart   # Edit / Verification / Payment / Subscription / Analytics / Work Hours (Coming Soon) / Language / Notifications (Coming Soon) / Help
│   │   │       └── edit_profile_screen.dart      # Role-aware PATCH /customers/me or /providers/me
│   │   └── rating/
│   │       ├── data/rating_repository.dart        # POST /ratings + pending ratings helpers (list + jobId Set)
│   │       └── presentation/
│   │           ├── rating_provider.dart           # RatingNotifier family — thumbs + tags + submit
│   │           └── rating_bottom_sheet.dart       # Role-branched tag set (customer: 5 tags / provider: 3 tags)
│   ├── customer/                        # ← Phase 06 — customer-only features
│   │   ├── home/home_page.dart                    # Direction C redesign (~1000 lines)
│   │   ├── booking/                               # 5-screen wizard + Grok AI helper
│   │   │   ├── data/booking_repository.dart
│   │   │   ├── data/ai_repository.dart            # POST /ai/improve-description
│   │   │   └── presentation/
│   │   │       ├── booking_provider.dart          # BookingNotifier + Stripe flow
│   │   │       ├── category_screen.dart
│   │   │       ├── job_description_screen.dart
│   │   │       ├── location_screen.dart           # flutter_map + drag pin (Riyadh default)
│   │   │       ├── booking_summary_screen.dart
│   │   │       └── booking_confirmation_screen.dart
│   │   ├── payments/
│   │   │   ├── data/payment_repository.dart
│   │   │   └── presentation/
│   │   │       ├── payment_provider.dart          # PaymentSummary model
│   │   │       ├── payment_receipt_screen.dart
│   │   │       └── payment_status_screen.dart
│   │   ├── history/presentation/
│   │   │   ├── history_page.dart
│   │   │   └── job_detail_page.dart               # before/after photo split + dispute CTA
│   │   ├── tracking/presentation/
│   │   │   ├── job_tracking_provider.dart         # SignalR ProviderLocationUpdated
│   │   │   └── tracking_page.dart                 # live map + rating CTA on Paid
│   │   ├── referral/
│   │   │   ├── data/referral_repository.dart
│   │   │   ├── domain/referral_info.dart
│   │   │   └── presentation/
│   │   │       ├── referral_provider.dart
│   │   │       └── referral_screen.dart
│   │   ├── reminders/
│   │   │   ├── data/reminders_repository.dart
│   │   │   └── presentation/
│   │   │       ├── reminders_provider.dart
│   │   │       └── reminders_screen.dart
│   │   └── dispute/presentation/raise_dispute_screen.dart
│   └── provider/                        # ← Phase 07 — provider-only features
│       ├── jobs/
│       │   ├── data/job_repository.dart           # JobSummary + JobDetail models; available/active/advance/after-photos
│       │   └── presentation/
│       │       ├── job_feed_provider.dart         # AsyncNotifier<List<JobSummary>> + SignalR NewJobAvailable
│       │       ├── job_detail_provider.dart       # FamilyAsyncNotifier keyed by jobId, 2-min countdown
│       │       ├── active_job_provider.dart       # Active job + 3s GPS broadcast during EnRoute
│       │       ├── completed_jobs_provider.dart   # FutureProvider — GET /providers/me/jobs?status=Paid
│       │       ├── job_feed_screen.dart           # 3 tabs (Available / Active / Completed)
│       │       ├── job_detail_screen.dart         # Map + countdown ring + accept/reject
│       │       ├── active_jobs_screen.dart        # Active tab — chip + rating CTA via shared RatingBottomSheet
│       │       ├── active_job_detail_screen.dart  # Status-switched actions + chat FAB
│       │       └── upload_after_photos_screen.dart
│       ├── onboarding/
│       │   ├── data/onboarding_api_service.dart   # + onboardingApiServiceProvider + onboardingStatusProvider
│       │   ├── domain/onboarding_status.dart      # VerificationTier + OnboardingStatus/Steps/Step
│       │   ├── domain/skill_test.dart             # SkillTest + Question + Option + Result + Answer
│       │   └── presentation/
│       │       ├── onboarding_hub_screen.dart     # 3-step stepper, GoRouter sub-routes
│       │       ├── id_upload_screen.dart
│       │       └── skill_test_screen.dart
│       ├── navigation/presentation/navigation_page.dart  # flutter_map + Geolocator pin
│       ├── earnings/
│       │   ├── data/earnings_repository.dart
│       │   └── presentation/
│       │       ├── earnings_provider.dart
│       │       ├── earnings_page.dart
│       │       └── payout_status_screen.dart     # Stripe Connect onboarding link
│       ├── analytics/
│       │   ├── data/analytics_repository.dart
│       │   ├── domain/analytics_models.dart
│       │   └── presentation/
│       │       ├── analytics_provider.dart       # 3 parallel API calls via Future.wait, 5-min keepAlive
│       │       └── analytics_screen.dart         # Earnings line + job stats bar + rating sparkline
│       └── subscription/
│           ├── data/subscription_repository.dart
│           ├── domain/subscription_info.dart
│           └── presentation/
│               ├── subscription_provider.dart
│               └── subscription_screen.dart      # Stripe PaymentSheet via SetupIntent
├── features/migration/                   # ← Phase 10 — hard-cutover gate
│   ├── data/migration_analytics.dart     # Fires `migration_opened_new_app` once per install
│   └── presentation/upgrade_required_screen.dart  # Defensive UPGRADE_REQUIRED takeover
└── main.dart             # Bootstrap: Firebase (graceful), Stripe, persisted locale, ProviderScope
```

Also added in Phase 06: `lib/widgets/main_scaffold_customer.dart` — the 4-tab
bottom nav + amber-gradient FAB hosting the customer `StatefulShellRoute`.

Phase 07 added `lib/widgets/main_scaffold_provider.dart` — the 4-tab
(Jobs / Earnings / Notifications / Profile) bottom nav hosting the
provider `StatefulShellRoute`; no center FAB (providers don't create
anything). Provider screens that span the full surface (job detail,
active job, navigation, after-photos, payout-status, onboarding hub,
subscription, analytics) live outside the shell.

## Routing (Phase 08)
- Single `routerProvider` (in `lib/app/router.dart`) returns a `GoRouter`
  wired to `rootNavigatorKey` (exported so the `NotificationHandler` can push
  from outside the widget tree). The redirect reads `access_token`, `user_role`,
  and `provider_tier` directly from `FlutterSecureStorage` so it is correct on
  cold-start even before `roleProvider` finishes hydrating. A `ValueNotifier`
  wired to `ref.listen(roleProvider, ...)` pulses the router on login/logout
  transitions via `refreshListenable`.
- Chat / notifications / profile are **no longer top-level** — they live under
  their role namespace, so the same code is routed through the shell (except
  `/<role>/chat/:jobId` which is off-shell because it pushes a full-screen
  conversation).
- Routes:
  - Auth: `/welcome` · `/login` · `/register` · `/otp?phone=…` ·
    `/forgot-password` · `/reset-password?phone=…`
  - Customer shell (persistent nav): `/customer/home` ·
    `/customer/history` · `/customer/history/:jobId` ·
    `/customer/notifications` · `/customer/profile` ·
    `/customer/profile/edit`
  - Customer flows (outside shell): `/customer/booking/category` ·
    `…/description` · `…/location` · `…/summary` · `…/confirmation` ·
    `/customer/tracking/:jobId` · `/customer/payment/receipt` ·
    `/customer/payment/status/:jobId` · `/customer/referral[?ref=CODE]` ·
    `/customer/reminders` · `/customer/dispute/raise` ·
    `/customer/chat/:jobId?name=…`
  - Provider shell (persistent nav): `/provider/jobs` ·
    `/provider/earnings` · `/provider/notifications` ·
    `/provider/profile` · `/provider/profile/edit`
  - Provider flows (outside shell): `/provider/job-detail/:jobId` ·
    `/provider/active-job/:jobId` ·
    `/provider/active-job/:jobId/after-photos` ·
    `/provider/navigation/:jobId` · `/provider/payout-status` ·
    `/provider/onboarding` · `/provider/onboarding/id-upload` ·
    `/provider/onboarding/skill-test` · `/provider/subscription` ·
    `/provider/analytics` · `/provider/chat/:jobId?name=…`
- Redirect matrix:
  - No token + any public path (`/welcome`, `/login`, `/register`, `/otp`,
    `/forgot-password`, `/reset-password`) → stay (provider role on
    `/forgot-password` or `/reset-password` bounces to `/login`).
  - No token + anything else → `/welcome`.
  - Token + role null (corrupted state) → clear access + refresh token →
    `/welcome`.
  - Token + public path → `/customer/home` or `/provider/jobs`.
  - Token + role=customer on `/provider/*` → `/customer/home`.
  - Token + role=provider on `/customer/*` → `/provider/jobs`.
  - Token + role=provider with `provider_tier` ∉ {`active`, `""`, `null`}
    and target ∉ `{/provider/onboarding, /provider/profile,
    /provider/notifications, /provider/chat}` → `/provider/onboarding`.
- `provider_tier` is written to secure storage by `onboardingStatusProvider`
  after a successful fetch (camelCase value — e.g. `"active"`,
  `"skillTested"`) and cleared by `AuthRepository.logout()` alongside the
  tokens.

## Notification handler & deep links (Phase 08)
- `lib/core/services/notification_handler.dart` contains **the only**
  FCM-type → route mapping in the app. Both the in-app notifications list
  (`notifications_screen.dart → handleNotificationTap`) and the push-payload
  dispatcher go through it.
- Constructed once in `main.dart` with the root `GoRouter` + a
  `ProviderContainer` (so it can read `roleProvider` without a widget ref).
  `fcm_service.setupFcmListeners` delegates tap events directly to it.
- Custom scheme `khudmati://` supported via `app_links: ^6.1.4`:
  - `khudmati://job/<jobId>` — customer → `/customer/tracking/<id>`,
    provider → `/provider/job-detail/<id>`
  - `khudmati://reminders` — customer → `/customer/reminders`
  - `khudmati://onboarding` — provider → `/provider/onboarding`
  - `khudmati://referral?ref=CODE` — customer → `/customer/referral?ref=CODE`
- Android manifest registers a `VIEW` intent-filter for scheme `khudmati`
  on `MainActivity` (`android:launchMode="singleTop"` preserved). iOS
  `Info.plist` adds `CFBundleURLTypes` with URL name `com.khudmati.app`.
- `handleNotificationTap` types covered: `JOB_ACCEPTED`, `PROVIDER_EN_ROUTE`,
  `PROVIDER_ARRIVED`, `JOB_COMPLETED`, `NEW_JOB_AVAILABLE`, `PAYMENT_HELD`,
  `PAYMENT_RELEASED`, `DISPUTE_OPENED`, `DISPUTE_RESOLVED`,
  `MAINTENANCE_REMINDER`, `VERIFICATION_APPROVED`, `VERIFICATION_REJECTED`,
  `SUBSCRIPTION_ACTIVATED`, `SUBSCRIPTION_CANCELLED`,
  `SUBSCRIPTION_PAYMENT_FAILED`, `NEW_CHAT_MESSAGE` / `CHAT_MESSAGE`,
  `ACCOUNT_SUSPENDED`, `ACCOUNT_REINSTATED`. Unknown types are silently
  ignored.

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

## Auth (Phase 04)
- `AuthRepository` (`lib/features/auth/data/auth_repository.dart`) is
  role-aware: `_prefix` returns `/auth/customers` or `/auth/providers` based on
  `roleProvider`. `register()` only sends `serviceCategories` when the role is
  `provider`; `loginWithEmail`, `forgotPassword`, and `resetPassword` throw
  `UnsupportedError` for providers so callers surface the right UI.
- `updateProfile({ fullName, email })` PATCHes `/customers/me` for customers
  (sending `fullName` + `email`) and `/providers/me` for providers (sending
  `fullName` only; the provider endpoint does not expose email).
- `AuthNotifier` (`AsyncNotifier<AuthState>`) exposes `register`, `verifyOtp`,
  `login`, `loginWithEmail`, and `logout`. `build()` calls `fetchMe()` when an
  access token is present and the role is known; the Dio 401 interceptor in
  `ApiClient` handles refresh transparently. `AppUser` replaces the per-app
  `CustomerUser` / `ProviderUser` — it carries `id`, `fullName`, `phone`, and
  an optional `email` (populated for customers).
- `AuthAuthenticated` carries both the `AppUser` and the `UserRole` so that
  downstream code doesn't have to re-read `roleProvider`.
- `logout()` clears access/refresh tokens and calls
  `roleProvider.notifier.clear()`, so the next cold start will land on
  `/welcome` with no role selected.
- Forgot/reset password are customer-only. The router bounces providers off
  `/forgot-password` and `/reset-password` back to `/login`, and the login
  page hides the "Forgot password?" link when `role == provider`.
- OTP screen shows the referral code bottom sheet only when
  `role == customer`. The sheet POSTs to `/customers/referral/apply` via
  `apiClientProvider`; the full referral feature lands in Phase 06.

## FCM
- `initLocalNotifications()` runs once inside `main()` when Firebase
  initialisation succeeds.
- `setupFcmListeners({ apiClient, handler, container })` wires foreground,
  opened-app, and initial-message handlers. Tap dispatch is delegated
  entirely to the shared `NotificationHandler` — see
  "Notification handler & deep links (Phase 08)" above.
- `registerFcmToken(apiClient, container)` posts the FCM token to
  `/customers/me/device-token` or `/providers/me/device-token` based on
  `roleProvider`; `onTokenRefresh` re-registers on rotation.

## SignalR
- `signalRServiceProvider` exposes a single `HubConnection` against
  `AppConfig.hubUrl` → `/hubs/jobs`.
- JWT access-token factory reads `access_token` from secure storage; audience
  claim (`customer` vs `provider`) on the server decides group membership.
- Auto-reconnect enabled; `ref.onDispose` stops the connection when the
  provider is disposed.
- `joinProviderGroups({isActive, hasActiveSubscription})` is a best-effort
  client hook: invokes `JoinProvidersAvailable` / `JoinProvidersPower` on
  the hub if defined. The server also auto-joins `provider-{id}` and
  `providers-available` based on the JWT audience, so this is additive —
  safe to call whether or not the server implements the RPCs.

## Shared features (Phase 05, re-namespaced in Phase 08)
All four feature areas live under `lib/features/shared/` and are now routed
**under each role's namespace** (`/customer/*` or `/provider/*`). The widget
code is role-agnostic and branches on `roleProvider` only where the API
contract actually differs. Phase 08 removed the top-level `/chat`,
`/notifications`, `/profile`, `/profile/edit` shims registered during
Phase 05.

### Chat (`features/shared/chat/`)
- `ChatScreen` is role-agnostic: `selfSenderType` is derived from
  `ref.watch(roleProvider)` so message bubble alignment works for both roles.
- `ChatNotifier` is a `FamilyAsyncNotifier<ChatState, String>` keyed by
  `jobId`; on `build()` it loads page 1 (50 messages), marks the thread as
  read, and subscribes to the SignalR `NewChatMessage` event filtered by
  `jobId`. Send errors are surfaced via `state.errorMessage == 'SEND_FAILED'`
  → `_ChatBody` pushes a localised snackbar.
- `unreadCountProvider` (`FutureProvider.family<int, String>`) exposes
  per-job unread count for badges in later phases.
- Routes: `/customer/chat/:jobId?name=…` · `/provider/chat/:jobId?name=…`.

### Notifications (`features/shared/notifications/`)
- `AppNotification` extends the legacy model with `type` + `data` fields so
  the tap handler can route correctly. `jobId` is surfaced as a convenience
  getter pulling `data['jobId']`.
- `NotificationRepository.getNotifications()` sends `role=<customer|provider>`
  as a query param so the backend can return role-appropriate types.
- `handleNotificationTap(context, ref, notification)` is exported from
  `notifications_screen.dart` and contains the single source of truth for
  notification routing (shared between in-app list and FCM handler in later
  phases). Handled types: `JOB_ACCEPTED`, `PROVIDER_EN_ROUTE`,
  `PROVIDER_ARRIVED`, `JOB_COMPLETED`, `NEW_JOB_AVAILABLE`, `PAYMENT_HELD`,
  `PAYMENT_RELEASED`, `DISPUTE_OPENED`, `DISPUTE_RESOLVED`,
  `MAINTENANCE_REMINDER`, `VERIFICATION_APPROVED`, `VERIFICATION_REJECTED`,
  `SUBSCRIPTION_ACTIVATED`, `SUBSCRIPTION_CANCELLED`,
  `SUBSCRIPTION_PAYMENT_FAILED`, `NEW_CHAT_MESSAGE`. Unknown types are
  silently ignored.
- Exposed providers: `notificationsNotifierProvider`,
  `unreadNotificationsCountProvider`, `notificationsHasMoreProvider`.
- Routes: `/customer/notifications` · `/provider/notifications` (tabs of
  their respective shells).

### Profile (`features/shared/profile/`)
- `ProfilePage` is a shared shell: it renders the header (avatar + name +
  phone) and the logout tile, and delegates the middle tile list to
  `CustomerProfileTiles` or `ProviderProfileTiles` based on
  `roleProvider`.
- Provider variant adds a verification badge under the name in the header.
- Customer tiles: Edit → `/customer/profile/edit`, Addresses (Coming Soon),
  Payment (Coming Soon), Referral → `/customer/referral`, Language toggle,
  Notifications → `/customer/notifications`, Help → `https://khudmati.app/#contact`,
  **Delete Account** (red, destructive — see below).
- Provider tiles: Edit → `/provider/profile/edit`, Verification →
  `/provider/onboarding`, Payment → `/provider/payout-status`, Subscription
  → `/provider/subscription`, Analytics → `/provider/analytics`, Work Hours
  (Coming Soon), Language toggle, Notifications (Coming Soon), Help,
  **Delete Account** (red, destructive — see below).
- Delete Account (Phase 12, Apple 5.1.1(v) + Google Data Safety):
  shared `showDeleteAccountDialog(context, ref)` in
  `features/shared/profile/presentation/delete_account_action.dart`
  shows a destructive confirmation, calls
  `AuthNotifier.deleteAccount()` → `AuthRepository.deleteAccount()`
  (`DELETE /customers/me` or `DELETE /providers/me`), clears tokens +
  role, and routes back to `/welcome`. Backend endpoints must land
  before first Apple submission — see
  `migration-plan/phase-12-implementation.md` §"Account deletion
  endpoints" for the server-side contract (hard-delete PII, soft-
  delete financial / audit rows, revoke JWTs, audit-log).
- `EditProfileScreen` hides the email field for providers and applies the
  role-specific full-name minimum (3 chars for customers, 2 for providers,
  matching the legacy `providerFullNameTooShort` message). Save calls
  `AuthRepository.updateProfile(...)` then invalidates `authNotifierProvider`.
- Routes: `/customer/profile` · `/customer/profile/edit` ·
  `/provider/profile` · `/provider/profile/edit`.

### Rating (`features/shared/rating/`)
- `RatingBottomSheet.show(context, jobId:, otherPartyName:)` opens a
  role-branched sheet. Both roles submit thumbs up/down + a positive tag set
  via `POST /ratings` (matches backend contract). Customer tag set: 5 tags
  (`arrived_on_time`, `clean_worksite`, `fair_pricing`, `professional`,
  `would_recommend`). Provider tag set: 3 tags (`easy_to_deal_with`,
  `described_problem_accurately`, `paid_promptly`).
- Sheet header differs: customers see provider avatar + `ratingQuestion(name)`;
  providers see `ratingCustomerQuestion`. Submit button is amber for
  customers, brand blue for providers.
- `RatingNotifier` is a `StateNotifier` family keyed by `jobId`; submit sets
  `error = 'SEND_FAILED'` on failure (mapped to `s.ratingSubmitError` in UI)
  and invalidates both pending-rating providers on success.
- Repository exposes `getPendingRatings()` (list for customer home banner) and
  `getPendingRatingJobIds()` (Set for provider feed to show a rating prompt
  on completed job cards).

## Dependencies pinned
`path_provider_android: 2.2.23` is pinned via `dependency_overrides` in
`pubspec.yaml` to avoid a flaky `jni 1.0.0` download from pub.dev. Remove
this override only if the pinned transitive dep can be fetched reliably in
your environment.

Phase 08 added `app_links: ^6.1.4` for custom-scheme deep links
(`khudmati://…`). Both Android (`<intent-filter>` on `MainActivity`) and
iOS (`CFBundleURLTypes`) already declare the scheme.

Phase 09 added `flutter_launcher_icons: ^0.13.1` and
`flutter_native_splash: ^2.3.10` (dev-dependencies). Both are config-only
— icon/splash assets themselves are not checked in and need to be
generated once the designer drops finals (see
`mobile/assets/icon/README.md` + `mobile/assets/splash/README.md`).

## Platform config (Phase 09)
### Android
- `android/app/src/main/AndroidManifest.xml` declares all runtime
  permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`,
  `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `ACCESS_BACKGROUND_LOCATION` (required for provider EnRoute GPS
  broadcasting; Play Store reviewers will scrutinise — the use-case is
  documented on the listing), `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_LOCATION`, `CAMERA`, `READ_EXTERNAL_STORAGE`
  (maxSdk 32), `READ_MEDIA_IMAGES`.
- `<queries>` block declares `PROCESS_TEXT`, `https`-scheme `VIEW`
  (required by `url_launcher` from Android 11+), and `DIAL`.
- Localised app label: `android:label="@string/app_name"` resolving to
  `Khudmati` via `values/strings.xml` and `خدمتي` via
  `values-ar/strings.xml`.
- `android/app/build.gradle.kts` enables `isMinifyEnabled` +
  `isShrinkResources` on the release build type and wires
  `proguard-rules.pro`. Rules preserve Stripe (heavy reflection), Firebase
  + GMS, SignalR (`com.microsoft.signalr` + OkHttp + Gson),
  `flutter_local_notifications`, and Play Core. Kotlin metadata is kept
  for reflection-based libraries.
- Custom-scheme intent-filter (`khudmati://`) remains on `MainActivity`
  from Phase 08 — untouched by Phase 09.

### iOS
- `ios/Runner/Info.plist` declares all usage-description keys:
  `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`,
  `NSLocationAlwaysUsageDescription` (kept for iOS 10 fallback),
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSPhotoLibraryAddUsageDescription`, `NSMicrophoneUsageDescription`.
- `UIBackgroundModes` declares `fetch`, `remote-notification`, and
  `location` (provider EnRoute GPS).
- `en.lproj/InfoPlist.strings` + `ar.lproj/InfoPlist.strings` hold the
  localised `CFBundleDisplayName` (`Khudmati` / `خدمتي`) and Arabic
  translations of all usage descriptions.
- ⚠️ `ar.lproj` must be registered as a `knownRegions` entry + a
  `PBXVariantGroup` for `InfoPlist.strings` must be added to the Xcode
  project on first open. The file tree on disk is ready; the
  `project.pbxproj` change must happen through Xcode (Project → Info →
  Localizations → `+` → Arabic). Push notifications + location work on
  both locales regardless — only the AR-localised launcher name depends
  on this wiring.

### Firebase
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
  are git-ignored. Commit checks in `.example` placeholders with
  instructions instead. Once Firebase console creates the project (or
  an existing project is reused per Phase 0 Decision B), drop the real
  files at `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist`.
- Firebase init already handles the placeholder case: `main.dart`
  wraps `Firebase.initializeApp()` in a try/catch and skips FCM
  registration if init fails, so the app still builds + runs without
  the real config.

## Migration gate (Phase 10)
- **Headers**: every Dio request carries `X-App-Package: com.khudmati.app`
  + `X-App-Version: 1.0.0+1` (sourced from
  `AppConfig.appPackage` / `AppConfig.appVersion`). Keep these in sync
  with Android `applicationId`, iOS bundle id, and pubspec `version`
  if you ever bump them.
- **Gate detection**: `ApiClient`'s `onResponse` + `onError` interceptors
  sniff both HTTP 426 and any payload shaped
  `{"success": false, "error": "UPGRADE_REQUIRED", "data": {"storeUrl": "…"}}`.
  When detected, they set `upgradeRequiredProvider` (a `StateProvider<AppUpgradeRequired?>`).
  Refresh logic is skipped when the gate fires — refresh would hit the
  same gate.
- **Takeover**: `KhudmatiApp.build` watches the provider and — when
  non-null — swaps the whole `MaterialApp.builder` child for
  `UpgradeRequiredScreen` (brand-blue surface, Download CTA to the
  provided `storeUrl` or `AppConfig.androidStoreUrl` / `iosStoreUrl`
  fallback, plus a Retry button that clears the flag for transient
  gate flips). The unified app should never actually trigger this —
  it fails closed defensively if the backend ever misclassifies
  an `X-App-Package: com.khudmati.app` request.
- **Migration analytics**:
  `features/migration/data/migration_analytics.dart` fires
  `migration_opened_new_app` (Firebase Analytics) once per install,
  gated by the secure-storage flag `migration_first_launch_logged`.
  Skipped gracefully when Firebase isn't configured (still sets the
  flag so debug logs don't repeat). Dependency:
  `firebase_analytics: ^10.8.0` (paired with the existing
  `firebase_core`).
- **Legacy apps**: both `mobile-customer/` and `mobile-provider/` carry
  the same gate (module-level `ValueNotifier<String?>
  upgradeRequiredNotifier` mounted via `MaterialApp.builder` →
  `ValueListenableBuilder<String?>` → `UpgradeRequiredScreen`).
  Their `appPackage` values are `com.khudmati.customer` /
  `com.khudmati.provider` so the backend can identify legacy traffic
  unambiguously.
- **Backend hand-off**: spec for the `Auth:ForceUpgradeForLegacyApps`
  feature flag, the 426 response contract, communication plan, and
  monitoring dashboard live in
  `migration-plan/phase-10-implementation.md`. Backend is intentionally
  untouched on this branch (executed during Phase 12 store submission).

### Stripe publishable key — env-gated
- `main.dart` reads
  `String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: 'pk_test_REPLACE_WITH_YOUR_TEST_KEY')`.
- Release build command:
  `flutter build apk --release --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_<KEY>`.
- Without the flag, PaymentSheet will throw `StripeException` against
  the placeholder key rather than silently using test mode in
  production.

### Icons + splash
- `pubspec.yaml` carries `flutter_launcher_icons` + `flutter_native_splash`
  config blocks; run after dropping the source assets:
  ```bash
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
- Source assets (not checked in): `assets/icon/icon.png` (1024x1024),
  `assets/icon/icon-foreground.png` (adaptive foreground),
  `assets/splash/logo.png`. README files in each folder document
  expected dimensions and safe-area rules.
- Splash/adaptive-icon background is brand blue `#1B4F72`.

## Logging (Phases 01 + 02 + 03 + 04 + 05 + 06)
Plan: `mobile/docs/logging-plan/` (six phases — **all complete**).
Phase 01 lays the foundation; Phase 02 instruments the seven
core-infrastructure files that sit between every user tap and every
observable side effect; Phase 03 wires the auth flow + the four
shared role-agnostic features (chat / notifications / profile /
rating); Phase 04 covers the full customer-only stack — booking
wizard + Stripe (T3), live GPS tracking (T3), payments / history /
home (selective T2), referral / reminders / dispute (T2); Phase 05
covers the full provider-only stack — 2-min job countdown (T3),
3-second EnRoute GPS broadcast (T3), active-job status machine
(T3), skill test session (T3), Stripe SetupIntent subscription
(T3), onboarding / navigation / earnings / analytics (T2);
Phase 06 hardens everything for release — `kReleaseMode` gate on
`v` / `d` / `i`, Firebase Crashlytics mirror for `e` / `c`,
`/debug/logs` viewer reachable in debug builds only, PII sweep
script, and `FlutterError` / `PlatformDispatcher` global error
handlers wired to `log.e` / `log.c`.

- **Library**: `talker_flutter: ^4.4.0` (core + UI),
  `talker_dio_logger: ^4.4.0` (Dio interceptor),
  `talker_riverpod_logger: ^4.4.0` (provider observer). Initialised by
  `AppLogger.bootstrap()` as the **first line** of `main()` so the
  pre-Firebase / pre-Stripe error paths route through it. The wrapper
  is a singleton — every call site uses `log.v / d / i / w / e /
  c(tag, msg, {data, error, stack})` from
  `core/logging/app_logger.dart`.
- **Format**: `[Tag] short message key=value key=value` — Tag is
  PascalCase class or top-level-function name (`[ApiClient]`,
  `[Router.redirect]`); message is imperative present-tense, no period;
  values are primitives only (no serialised maps).
- **Redaction policy** (codified in `core/logging/redact.dart`):
  `redactPhone` → `+96650000****1234`; `redactEmail` →
  `a***@example.com`; `redactToken` → `tok:<first8>`; `redactLatLng` →
  2-decimal rounding (≈ 1.1 km); `redactOtp` → `*** (len=N)`;
  `redactUrl` strips token / OTP / password / secret query keys
  (case-insensitive — `ref=` survives because referral codes are not
  secret). Passwords + Stripe client secrets are **never** logged. See
  `mobile/docs/logging-plan/README.md` for the full table.
- **Levels**: `verbose` (chatty per-tick — GPS broadcast, SignalR
  heartbeat, off by default), `debug` (entry/exit/branch — most lines
  land here), `info` (state transitions — login success, job accepted),
  `warning` (recoverable oddities — token refresh kicked in), `error`
  (caught exceptions — always pass `error` + `stack`), `critical`
  (unrecoverable — corrupt token, redirect loop).
- **Console + history**: `useConsoleLogs: kDebugMode` so release builds
  don't hit `dart:developer.log`; `maxHistoryItems: 500` powers the
  in-app viewer.
- **Debug log viewer**: `LogViewerScreen` mounted at `/debug/logs` only
  when `kDebugMode`. The redirect guard short-circuits on `/debug/`
  prefixes so the viewer is reachable even when auth state is broken.
  Open it with a long-press on the version label (`v1.0.0+1`) at the
  bottom of the profile page (`features/shared/profile/presentation/profile_page.dart`).
- **Riverpod**: `loggerProvider` (returns `AppLogger.instance`) +
  `talkerProvider` (raw `Talker` for adapters that need the underlying
  type). Override `loggerProvider` in tests with a fresh `AppLogger`
  to assert on log output.
- **Lints**: `analysis_options.yaml` has `analyzer.errors.avoid_print:
  error`. Every existing `debugPrint(...)` call in `lib/` was migrated
  in Phase 01. A repo-wide grep for `debugPrint(` or `print(` in
  `mobile/lib/` should return zero results outside comments.

### Phase 02 wiring
- **`ApiClient`** — `TalkerDioLogger` is registered LAST in the
  interceptor chain (so it sees the final outgoing request after our
  auth-header / upgrade-gate logic) with bodies + headers OFF (PII
  guard — turning them on would leak OTPs, passwords, bearer tokens).
  Manual logs cover constructor `init`, request entry (`hasAuth`),
  upgrade-gate hits from both 200 and 4xx, refresh start/ok/failed
  (with `redactToken(newAccess)`), passthrough errors, and `tokens
  cleared`.
- **`SignalRService`** — `connect` logs `init` with `hasToken`;
  `onclose` / `onreconnecting` / `onreconnected` are wired before
  `start()`; `joinProviderGroups` logs entry + per-group `join ok` /
  `join failed`; `disconnect` logs `stop on dispose`.
- **`fcm_service`** — `initLocalNotifications` rethrows after logging
  (so `main.dart`'s graceful try/catch still skips FCM if it fails);
  `setupFcmListeners` logs `listeners wired` + per-event lines for
  `fg msg` / `tap opened app` / `tap cold start`; `registerFcmToken`
  logs start / ok / failed and `token rotated, re-registering` on
  refresh. **The FCM token is never logged.**
- **`NotificationHandler`** — every dispatched route emits
  `[NotifHandler] route target=… source=fcm:<TYPE>` or
  `source=deeplink:<HOST>`; `handleFcmTap` and `handleDeepLink` log
  entry with type / host / `redactUrl(uri)`; unknown type / host
  branches emit `w` (instead of the Phase-01 `debugPrint` swap).
- **`router.dart`** — every redirect entry logs `v` with path / token
  presence / role / tier; every branch return logs `d` with
  `from` / `to` / `reason` (`no_token`, `public`, `wrong_role`,
  `tier_gate`, `corrupt_state`, `authed_on_public`,
  `provider_no_password_recovery`, `allow`); `refreshListenable`
  pulses log `refresh pulse reason=role_change prev=… next=…`;
  corrupt-state token wipe logs `w 'corrupt state, clearing tokens'`;
  `TalkerRouteObserver(log.talker)` is installed on the root
  `GoRouter` so push / pop / replace events show up automatically.
- **`role_provider`** — `setRole` / `clear` log at `info`; `_hydrate`
  logs at `debug`. **`locale_provider`** — `setLocale` logs at
  `info`; `loadPersisted` logs at `debug`.
- **Riverpod observer** — `TalkerRiverpodObserver(talker: log.talker)`
  is registered on the **single** root `ProviderContainer` (built
  before `runApp`) so provider build / dispose / state changes /
  errors all converge on the same Talker history as Dio, SignalR,
  FCM, and router events. Default settings log every category — tighten
  via `TalkerRiverpodLoggerSettings` if the volume becomes noisy.

### Phase 03 wiring
Tag → file map (every line is `[Tag] message key=value …`):

| Tag | File | Tier |
|---|---|---|
| `AuthRepo` | `features/auth/data/auth_repository.dart` | T3 |
| `AuthNotifier` | `features/auth/presentation/auth_provider.dart` | T3 |
| `WelcomeScreen` | `features/auth/presentation/welcome_screen.dart` | T1 |
| `LoginPage` | `features/auth/presentation/login_page.dart` | T2 |
| `RegisterScreen` | `features/auth/presentation/register_screen.dart` | T2 |
| `OtpScreen` | `features/auth/presentation/otp_screen.dart` | T3 |
| `ForgotPassword` | `features/auth/presentation/forgot_password_screen.dart` | T1 |
| `ResetPassword` | `features/auth/presentation/reset_password_screen.dart` | T1 |
| `ChatRepo` | `features/shared/chat/data/chat_repository.dart` | T1 |
| `ChatNotifier` | `features/shared/chat/presentation/chat_provider.dart` | T3 |
| `ChatScreen` | `features/shared/chat/presentation/chat_screen.dart` | T1 |
| `NotifRepo` | `features/shared/notifications/data/notification_repository.dart` | T1 |
| `NotifNotifier` | `features/shared/notifications/presentation/notifications_provider.dart` | T2 |
| `NotifList` | `features/shared/notifications/presentation/notifications_screen.dart` | T2 |
| `ProfilePage` | `features/shared/profile/presentation/profile_page.dart` | T2 |
| `ProfileTilesC` | `features/shared/profile/presentation/profile_tiles_customer.dart` | T1 |
| `ProfileTilesP` | `features/shared/profile/presentation/profile_tiles_provider.dart` | T2 |
| `EditProfile` | `features/shared/profile/presentation/edit_profile_screen.dart` | T2 |
| `DeleteAccount` | `features/shared/profile/presentation/delete_account_action.dart` | T3 |
| `RatingRepo` | `features/shared/rating/data/rating_repository.dart` | T1 |
| `RatingNotifier` | `features/shared/rating/presentation/rating_provider.dart` | T2 |
| `RatingSheet` | `features/shared/rating/presentation/rating_bottom_sheet.dart` | T1 |

- **Auth repo (T3)** — every public method emits `d '<m> start' role=…
  endpoint=…` with redacted phone / email / OTP, then `i '<m> ok'` (with
  `redactToken(accessToken)` + `userId` for login/loginWithEmail/verifyOtp)
  on 2xx, or `e '<m> failed' code=$serverCode` on `DioException`, or
  `e '<m> crashed'` (with stack) on unexpected throws. `logout` adds
  `i 'tokens cleared'`; `deleteAccount` adds `i 'tokens cleared after
  delete'`. `loginWithEmail` / `forgotPassword` / `resetPassword` log
  `w '<m> blocked'` instead when `role == provider`.
- **AuthNotifier (T3)** — `build` logs `d 'build' hasToken=$b role=$role`
  then either `i 'no session'`, `w 'token without role — forcing
  re-auth'`, `i 'fetchMe ok'`, or `w 'fetchMe failed — treating as
  unauthenticated'`. Each method follows the
  `d '<m> start' → i '<m> ok' / w '<m> failed' code=$code` pattern.
  Riverpod observer from Phase 02 already covers the resulting
  `state =` emissions.
- **OtpScreen (T3)** — `init` logs the redacted phone + role; the
  per-second timer emits `v 'resend tick' secondsLeft=$n` (verbose so
  it stays off by default in release); `resend tap → resend ok / w
  resend failed code=$code`; `verify tap` includes only `otpLen`
  (never the value); on success `i 'nav next' target=…`. The customer
  referral bottom-sheet — also under tag `OtpScreen` — logs `d
  'referral apply start' ref=$code` then `i ok / w failed code=$code /
  e crashed`.
- **Login / Register / ForgotPassword / ResetPassword** — each
  `_submit` first emits `d 'submit blocked' reason=validation_failed`
  if `formKey.validate()` returns false; otherwise `d 'submit'` with
  the relevant context (mode, role, redacted phone) and on success an
  `i 'nav next' target=…` line. Failures emit `w 'submit failed'`
  (for login/register/reset, with `code=$serverCode`) or rely on
  `AuthNotifier`'s own logs.
- **Chat** — `ChatRepo` logs `getMessages / sendMessage / markAsRead`
  start lines (no message text). `ChatNotifier` logs `build`, `load
  page ok` / `load failed`, `signalr subscribe` / `signalr msg`, `send
  start` / `send ok` / `w 'send failed' code=SEND_FAILED`, and
  `mark read`. `ChatScreen` logs `load prev page tap` and `send button
  tap` (length only, never text).
- **Notifications** — `NotifRepo.getNotifications` logs page + role;
  `NotifNotifier` logs `refresh`, `load ok count=$n totalCount=$t`, or
  `load failed`. `NotifList.tap` logs `type=$type jobId=$jobId`
  immediately before calling `handleNotificationTap` — which itself is
  already logged by `NotificationHandler` in Phase 02 when invoked
  from FCM (the in-app list re-uses the same dispatcher).
- **Profile** — `ProfilePage` logs `logout tap` + the long-press →
  `/debug/logs`. Customer + provider tile lists log `tile tap
  tile=<name>` for every row, including a separate `(coming soon)`
  variant for the placeholder rows. `EditProfile` logs `open` (with
  redacted email + role), `save tap nameChanged=$b emailChanged=$b`,
  then `save ok / w save failed code=$code / e save crashed`.
  `DeleteAccount` (Apple 5.1.1(v)) traces every step: `dialog shown
  → confirm tap → api start (role + endpoint) → api ok / e api failed
  code=$code / e api crashed → nav welcome`.
- **Rating** — `RatingRepo.submitRating` logs `jobId / isPositive /
  tagCount`. `RatingNotifier.submit` emits the canonical line
  `d 'submit start' jobId=… thumbsUp=… tags=…` then `i 'submit ok'`
  / `w 'submit failed' code=SEND_FAILED` / `e 'submit crashed'`.
  `RatingSheet` logs `tag toggle` + `submit tap` taps.
- **Validation-error policy**: client-side validation failures log the
  *reason* (e.g. `reason=validation_failed`, `reason=no_categories`),
  never the offending value. PII still routes through Phase 01
  `redactPhone` / `redactEmail` / `redactOtp` / `redactToken` helpers.

### Phase 04 wiring
Tag → file map for `lib/features/customer/**`:

| Tag | File | Tier |
|---|---|---|
| `BookingRepo` | `customer/booking/data/booking_repository.dart` | T2 |
| `AiRepo` | `customer/booking/data/ai_repository.dart` | T1 |
| `BookingNotifier` | `customer/booking/presentation/booking_provider.dart` | T3 |
| `CategoryScreen` | `customer/booking/presentation/category_screen.dart` | T1 |
| `JobDescription` | `customer/booking/presentation/job_description_screen.dart` | T2 |
| `LocationScreen` | `customer/booking/presentation/location_screen.dart` | T2 |
| `BookingSummary` | `customer/booking/presentation/booking_summary_screen.dart` | T3 |
| `BookingConfirm` | `customer/booking/presentation/booking_confirmation_screen.dart` | T1 |
| `CustomerHome` | `customer/home/home_page.dart` | T2 (narrow) |
| `TrackingNotifier` | `customer/tracking/presentation/job_tracking_provider.dart` | T3 |
| `TrackingPage` | `customer/tracking/presentation/tracking_page.dart` | T2 |
| `PaymentRepo` | `customer/payments/data/payment_repository.dart` | T1 |
| `PaymentReceipt` | `customer/payments/presentation/payment_receipt_screen.dart` | T1 |
| `PaymentStatus` | `customer/payments/presentation/payment_status_screen.dart` | T1 |
| `HistoryPage` | `customer/history/presentation/history_page.dart` | T1 |
| `JobDetail` | `customer/history/presentation/job_detail_page.dart` | T2 |
| `ReferralRepo` | `customer/referral/data/referral_repository.dart` | T1 |
| `ReferralNotifier` | `customer/referral/presentation/referral_provider.dart` | T2 |
| `ReferralScreen` | `customer/referral/presentation/referral_screen.dart` | T1 |
| `RemindersRepo` | `customer/reminders/data/reminders_repository.dart` | T1 |
| `RemindersNotifier` | `customer/reminders/presentation/reminders_provider.dart` | T2 |
| `RaiseDispute` | `customer/dispute/presentation/raise_dispute_screen.dart` | T2 |

- **BookingNotifier (T3)** — every state-machine setter (`setCategory`,
  `setDescription`, `setLocation`, `setAmount`, `addPhoto`, `removePhoto`,
  `reset`) emits a `d` line with the relevant primitive. `submitBooking`
  begins with `i 'submit start' category=… amount=… bypass=…` and then
  branches:
  - **Bypass path** (`AppConfig.bypassPayments == true`):
    `w 'bypass path — no Stripe' reason=qa_build` →
    `i 'api start' endpoint=/bookings/jobs` →
    `i 'api ok' jobId=$id bypass=true`. Photo upload failures log
    `w 'photo upload failed (bypass) — ignored'` but never abort the
    flow (matches Phase 11 QA-build behaviour).
  - **Stripe path**: `d 'create intent start' amount=…` →
    `i 'intent ok' paymentIntentId=… clientSecret=${redactToken(...)} chargedAmount=… referralDiscount=… creditApplied=…`
    → `d 'present sheet'` → `i 'sheet confirmed'` →
    `d 'confirm start' paymentIntentId=…` → `i 'confirm ok' jobId=… transactionId=…`.
  - `StripeException` always logs `e 'stripe exception'
    code=${error.code.name}` plus a softer `w 'sheet cancelled'` /
    `w 'sheet failed'` for grep-ability.
  - `DioException` logs `e 'api failed' status=…`; bare throws log
    `e 'submit crashed'` with stack.
  - **Stripe redaction**: `clientSecret` always passes through
    `redactToken(...)`; `paymentMethod` / `customerId` / Stripe object
    payloads are **never** logged in any form. The bypass sentinel
    `BYPASSED` is logged literally (so post-hoc analysis can tell a QA
    transaction from a real one).
- **TrackingNotifier (T3)** — `build` logs `d 'build' jobId=…` then
  `i 'initial status' status=…` once the API returns. SignalR
  subscriptions log `d 'signalr subscribe' event=JobStatusChanged|ProviderLocationUpdated`.
  Every status delta logs `i 'status transition' from=$old to=$new`.
  Every GPS frame logs `v 'loc update' coords=${redactLatLng(...)} distanceKm=… ageMs=…`
  — verbose so the 3-second cadence stays off by default in release.
  `ref.onDispose` logs `d 'unsubscribed'`.
- **CustomerHome (T2 narrow)** — only the side-effectful spots get logs
  to keep the 1.2k-line file readable: `d 'search changed' len=$n` (no
  value), `d 'category tap' id=$id bypassPicker=true source=…`
  (sources: `context_chip` / `grid` / `book_again` / `search_filtered`),
  `d 'fab tap' source=emergency_chip`,
  `d 'rating banner tap' jobId=$id` / `'rating banner dismiss'`. Pure
  presentational widgets get nothing.
- **Booking screens** — `JobDescription` traces the AI helper
  end-to-end (`d 'improve start' inputLen=… category=…` →
  `i 'improve ok' outputLen=…` / `w 'improve failed'`) and logs
  `d 'ai use tap' len=…` + `d 'next tap' len=…`. `LocationScreen`
  logs `d 'gps tap'`, `i 'gps ok' coords=${redactLatLng(...)}` /
  `w 'gps denied'` / `w 'gps failed'`, plus
  `d 'geocode start' coords=… → d 'geocode ok' addrLen=… / w 'geocode empty' / w 'geocode failed'`.
  `BookingSummary` logs `d 'pay tap' amount=… bypass=…` /
  `d 'pay blocked' reason=validation_failed`, then on completion
  `i 'nav next' target=/customer/payment/receipt jobId=…`.
  `BookingConfirm` traces the SignalR path: `d 'join job group'`,
  `i 'job accepted' jobId=…` / `w 'job expired' jobId=…` plus
  `w 'signalr connect failed'` / `w 'JobAccepted parse failed'` /
  `w 'JobExpired parse failed'` for the catch arms.
- **Referral / Reminders / Dispute (T2)** — repositories log every
  start line; notifiers wrap each method with
  `d '<m> start' → i '<m> ok' / w '<m> failed' code=<server-code>`.
  Concretely: `ReferralNotifier` logs `apply ok' discountPct=…` and
  `apply failed' code=REFERRAL_CODE_NOT_FOUND|REFERRAL_ALREADY_USED|REFERRAL_SELF_REFERRAL|REFERRAL_CODE_EXPIRED`;
  `RemindersNotifier.snooze` blocks days > 30 with
  `w 'snooze blocked' reason=SNOOZE_DAYS_EXCEEDED` (the `markBooked`
  deep-link emits `i 'deep link to booking' id=…`);
  `RaiseDispute` logs `submit start jobId=… reasonLen=…` →
  `i 'submit ok' disputeId=…` /
  `w 'submit failed' code=DISPUTE_WINDOW_CLOSED|DISPUTE_ALREADY_EXISTS|DISPUTE_NOT_ALLOWED_IN_CURRENT_STATUS`.
- **Payments (T1)** — `PaymentRepo` logs `createIntent / confirmPayment / getMyTransactions`
  start lines with primitives only. `PaymentReceipt` logs `open` +
  `view order tap` (job id only). `PaymentStatus` logs
  `load start jobId=… → load ok found=$bool status=… / w 'load failed'`.
- **History / Job detail (T2)** — `HistoryPage` logs the list-load
  count and each card tap with `jobId / status`. `JobDetail` logs
  `load ok jobId=… status=… beforeCount=… afterCount=… hasOpenDispute=…`
  plus `d 'raise dispute tap' jobId=…`.
- **Stripe redaction reminder**: anywhere a Stripe payload is touched
  outside `BookingNotifier`, route through `redactToken(...)`. Logging
  a raw `clientSecret`, `paymentMethod`, or full Stripe response object
  is treated as a Phase-04 regression.

### Phase 05 wiring
Tag → file map for `lib/features/provider/**`:

| Tag | File | Tier |
|---|---|---|
| `JobRepo` | `provider/jobs/data/job_repository.dart` | T2 |
| `JobFeedNotifier` | `provider/jobs/presentation/job_feed_provider.dart` | T2 |
| `JobDetailNotifier` | `provider/jobs/presentation/job_detail_provider.dart` | T3 |
| `ActiveJobNotifier` | `provider/jobs/presentation/active_job_provider.dart` | T3 |
| `CompletedJobs` | `provider/jobs/presentation/completed_jobs_provider.dart` | T1 |
| `JobFeedScreen` | `provider/jobs/presentation/job_feed_screen.dart` | T2 |
| `JobDetailScreen` | `provider/jobs/presentation/job_detail_screen.dart` | T2 |
| `ActiveJobsScreen` | `provider/jobs/presentation/active_jobs_screen.dart` | T1 |
| `ActiveJobDetail` | `provider/jobs/presentation/active_job_detail_screen.dart` | T3 |
| `UploadAfterPhotos` | `provider/jobs/presentation/upload_after_photos_screen.dart` | T2 |
| `OnboardingApi` | `provider/onboarding/data/onboarding_api_service.dart` | T2 |
| `OnboardingHub` | `provider/onboarding/presentation/onboarding_hub_screen.dart` | T2 |
| `IdUploadScreen` | `provider/onboarding/presentation/id_upload_screen.dart` | T2 |
| `SkillTest` | `provider/onboarding/presentation/skill_test_screen.dart` | T3 |
| `ProviderNav` | `provider/navigation/presentation/navigation_page.dart` | T2 |
| `EarningsRepo` | `provider/earnings/data/earnings_repository.dart` | T2 |
| `EarningsNotifier` | `provider/earnings/presentation/earnings_provider.dart` | T2 |
| `PayoutStatus` | `provider/earnings/presentation/payout_status_screen.dart` | T2 |
| `SubscriptionRepo` | `provider/subscription/data/subscription_repository.dart` | T2 |
| `SubscriptionNotifier` | `provider/subscription/presentation/subscription_provider.dart` | T3 |
| `Subscription` | `provider/subscription/presentation/subscription_screen.dart` | T3 |
| `AnalyticsRepo` | `provider/analytics/data/analytics_repository.dart` | T1 |
| `AnalyticsNotifier` | `provider/analytics/presentation/analytics_provider.dart` | T2 |
| `AnalyticsScreen` | `provider/analytics/presentation/analytics_screen.dart` | T1 |

- **JobDetailNotifier (T3)** — `build` logs `d 'build' jobId=…`; the
  initial countdown emits `i 'countdown start' jobId=… seconds=120`;
  every per-second tick logs `v 'tick' remaining=…` (verbose so it
  stays out of the default view); expiry logs
  `w 'expired' jobId=…`. `accept` and `reject` follow the canonical
  `d '<m> start' → i '<m> ok' / e '<m> failed' / w 'reject failed'`
  shape.
- **ActiveJobNotifier (T3)** — every status change is logged once with
  `i 'status' from=… to=… source=signalr|advance_api`. The 3-second
  GPS broadcast emits `i 'gps broadcast start' intervalMs=3000` on
  entering EnRoute, then per-frame
  `v 'gps push' coords=${redactLatLng(...)}` (verbose), and
  `i 'gps broadcast stop' reason=arrived|disposed|restart` when the
  timer is torn down. GPS errors log `e 'gps failed'` with stack;
  permission denials log `w 'gps permission denied'`.
- **ActiveJobDetail (T3)** — every status-machine CTA logs
  `d 'action tap' action=enroute|arrived_or_start|finish_upload`.
  The chat FAB tap logs `d 'chat fab tap' jobId=…`. The actual API
  result is logged by `ActiveJobNotifier`'s `status` transition line,
  so the screen only emits user-intent.
- **UploadAfterPhotos (T2)** — `d 'pick image' source=camera|gallery
  → d 'pick ok' bytes=… count=…` or
  `w 'pick rejected' reason=too_large bytes=…`. The
  upload + advance gate emits `d 'advance blocked' reason=no_after_photo`
  when the list is empty, otherwise
  `d 'upload start' count=… → i 'upload ok' / e 'upload failed'`.
- **OnboardingApi (T2)** — every method follows the canonical
  `d '<m> start' → i '<m> ok' / e '<m> failed'` shape with no PII
  (only doc type + total bytes for `submitDocuments`). The persisted-
  tier write inside `onboardingStatusProvider` logs
  `i 'tier bumped' from=… to=…` whenever the new tier differs from the
  stored value, so the post-skill-test `provider_tier` change is
  traceable into the next router redirect.
- **SkillTest (T3)** — `d 'init' category=…` →
  `i 'session start' sessionId=… category=… total=…`; per-question
  `d 'answer' q=$idx optionId=…`; `d 'submit start' sessionId=…` →
  `i 'session ok' score=… total=… passed=…` or
  `w 'session failed cooldown' nextRetryAt=…` for failed attempts.
  Errors log `e 'submit failed'` / `w 'session start failed'` with
  the category context.
- **ProviderNav (T2)** — `d 'init' jobId=…`;
  `d 'permission check' → i 'permission ok' / w 'permission denied' level=denied|deniedForever`;
  `d 'get current position' → v 'pos' coords=${redactLatLng(...)} / e 'pos failed'`.
  The advance-status CTA logs `d 'advance tap' jobId=… status=…`
  before delegating to `ActiveJobNotifier` (which handles the actual
  status transition logging).
- **Subscription (T3)** — full Stripe SetupIntent trace:
  `i 'subscribe start' → d 'setup intent start' → i 'setup intent ok'
  clientSecret=${redactToken(secret)} → d 'sheet present' →
  i 'sheet confirmed' → activate via SubscriptionNotifier
  (d 'activate api start' → i 'activate ok' status=Active /
  w 'activate failed' code=PROVIDER_NOT_ACTIVE|ALREADY_SUBSCRIBED|PAYMENT_METHOD_INVALID|STRIPE_ERROR)`.
  `StripeException` always logs `e 'sheet failed' code=${error.code.name}`,
  with a softer `w 'sheet cancelled'` for `FailureCode.Canceled` so
  cancellations are easy to grep. Cancellation flow logs
  `d 'cancel start' → i 'cancel ok' cancelsAt=…` /
  `w 'cancel failed' code=…`. **Stripe redaction:** `clientSecret`
  and `paymentMethodId` always pass through `redactToken(...)`; the
  derived `siId` (from `clientSecret.split('_secret_')`) is the
  Stripe SetupIntent id, safe to log in full.
- **Analytics (T2)** — `AnalyticsNotifier.load` emits
  `d 'load start' period=… cache=miss` →
  `d 'parallel fetch start' → i 'parallel fetch ok' period=…` or
  `e 'parallel fetch failed'`. `AnalyticsScreen` logs each period
  chip tap with `d 'period chip tap' period=…`. The 5-min keepAlive
  cache is documented but not logged on hit (the FutureProvider only
  rebuilds on miss, so seeing a `load start` line *is* a cache miss).
- **Earnings (T2)** — `EarningsRepo` logs every method start;
  `EarningsNotifier.build` adds
  `i 'load summary ok' pending=… available=… stripe=…`;
  `PayoutStatus` traces the Stripe Connect onboarding link launch:
  `d 'connect tap' → i 'open external' url=${redactUrl(url)}` (the
  URL is from Stripe and contains a one-shot account-link token —
  `redactUrl` keeps the host + path but strips any sensitive query
  keys).
- **Provider-tier gate**: Phase 02 router redirect logs cover the
  redirect to `/provider/onboarding`; Phase 05 adds the
  `OnboardingApi` `tier bumped` line so a successful skill test or
  ID approval that bumps the persisted tier is traceable into the
  next router redirect.
- **Stripe redaction reminder (Phase 05 surface)**: anywhere a
  `clientSecret` or `paymentMethodId` is touched in
  `subscription_repository.dart` / `subscription_screen.dart` /
  `subscription_provider.dart`, route through `redactToken(...)`.
  Same rule as Phase 04 — logging a raw secret is treated as a
  regression.

### Phase 06 wiring
- **Release log gate** — `AppLogger.v` / `d` / `i` early-return
  when `kReleaseMode` is true, so `verbose` / `debug` / `info`
  emit nothing in a release APK / IPA. `w` / `e` / `c` keep
  firing — they're the levels operators care about. Talker
  history still respects `maxHistoryItems: 500` for the in-app
  viewer (debug only) but the release no-op short-circuits before
  the `_format` / `_emit` work, so there's no string-concat cost
  in release.
- **Crashlytics sink** — `lib/core/logging/crashlytics_sink.dart`
  wraps `FirebaseCrashlytics.recordError(...)`. Wired by
  `AppLogger.attachCrashlytics(...)` from `main.dart`, but only
  when **(a)** `Firebase.initializeApp()` succeeded *and* **(b)**
  `kReleaseMode` is true — debug crashes stay local, the
  Crashlytics dashboard is for production traffic only.
  `error`-level logs go through `recordError(fatal: false)`;
  `critical`-level logs go through `recordError(fatal: true)` so
  they surface alongside hard crashes. The `data` map (already
  redacted at the call site) is flattened to `key=value` strings
  and attached as `information`. Sink reference is held on the
  `AppLogger` instance and cleared via the `@visibleForTesting`
  `detachCrashlytics()` hook.
- **Global error handlers** — `main.dart` installs
  `FlutterError.onError` (→ `log.e('FlutterError', …)`) and
  `PlatformDispatcher.instance.onError` (→ `log.c('PlatformError', …)`)
  before any other init, so a Stripe / Firebase / deep-link
  bootstrap throw lands in the same Talker history as runtime
  errors and is mirrored to Crashlytics in release.
- **Debug log viewer gating** — `/debug/logs` `GoRoute` is
  registered inside `if (kDebugMode)` in `lib/app/router.dart`,
  and the redirect guard short-circuits on `/debug/` prefixes
  with the same gate. In a release build the route is unknown to
  GoRouter and resolves to the standard error page — there is no
  way to reach the Talker UI from a shipped app.
- **PII sweep script** — `mobile/docs/logging-plan/check_pii.sh`
  greps `mobile/lib/` (excluding `core/logging/redact.dart`) for
  bearer tokens, Stripe `pi_…` / `seti_…` / `sk_(live|test)_…`
  identifiers, and raw `print(` / `debugPrint(` calls. Exits 0
  on a clean tree, 2 on a finding. Run locally before merging
  any logging-plan PR; wire into CI when the project gets a
  pipeline. Uses `rg` if available, `grep -r` as a fallback.
- **`firebase_crashlytics: ^3.5.0`** added to `pubspec.yaml`
  alongside the existing `firebase_core` / `firebase_messaging` /
  `firebase_analytics` deps. The Android Gradle Crashlytics
  plugin still needs to be wired in `android/build.gradle.kts` +
  the iOS Run Script phase added in Xcode before symbol uploads
  start working — both are documented but not yet executed
  because they require the real `google-services.json` /
  `GoogleService-Info.plist` (still git-ignored placeholders).
  Until those land, `attachCrashlytics()` is reached but the
  underlying `FirebaseCrashlytics.instance` calls degrade to
  no-ops on the wire — no exception, no error.
- **Acceptance criteria status**:
  - ✅ release-build no-op confirmed by code (`kReleaseMode`
    early-return in `app_logger.dart`); empirical verification
    (`adb logcat | grep -i khudmati` after release install)
    pending the same device test pass that ships Phase 11.
  - 🟡 Crashlytics end-to-end delivery (button-tap throw → dashboard
    in 5 min) requires real Firebase config — scaffolded, not
    runtime-verified.
  - ✅ `check_pii.sh` returns 0 on the current tree.
  - ✅ This section updates `mobile/CLAUDE.md`.
  - ✅ Debug log viewer is unreachable in release builds.

## Migration status
See `migration-plan/README.md` for the full 14-phase plan. Phase-by-phase
completion is tracked in git history on branch `feat/unified-app`.

| Phase | Title | Status |
|---|---|---|
| 00 | Prep & decisions | ✅ complete |
| 01 | Scaffold unified app | ✅ complete (commit `787fb7a`) |
| 02 | Port core / shared infrastructure | ✅ complete (commit `c6e3d55`) |
| 03 | Role selection + router skeleton | ✅ complete (commit `3a9123a`) |
| 04 | Shared auth screens (real phone/OTP/password) | ✅ complete |
| 05 | Shared features (chat / notifications / profile / rating) | ✅ complete |
| 06 | Customer-only features (home, booking, payments, history, tracking, referral, reminders, dispute) + `MainScaffoldCustomer` | ✅ complete |
| 07 | Provider-only features (job feed, onboarding, navigation, earnings, analytics, subscription) + `MainScaffoldProvider` | ✅ complete |
| 08 | Unified router + `NotificationHandler` + `khudmati://` deep links + provider-tier gate | ✅ complete |
| 09 | Platform config — permissions, Firebase placeholders, icons/splash, ProGuard, Stripe `--dart-define` | ✅ complete |
| 10 | Existing-user migration — hard cutover gate (`X-App-Package` headers, `UpgradeRequiredScreen`, `migration_opened_new_app` analytics, legacy-app patches) | ✅ complete |
| 11 | End-to-end verification — checklist scaffolded (`docs/verification-checklist.md`); device/release-build sign-off pending manual run | 🟡 scaffolded |
| 12 | Store submission — listing copy (EN + AR), rejection log, in-app account deletion for Apple 5.1.1(v), backend prereqs specced | 🟡 scaffolded |
| 13 | Deprecate legacy apps | ⏳ queued |

## Verification
- `flutter analyze` → 0 errors / 0 warnings; 60 `info`-level lints (mostly
  `withOpacity` deprecations from the Flutter SDK upgrade — non-blocking
  for release builds, slated for a follow-up cleanup ticket).
- `flutter test` → `test/widget_test.dart` exercises the role_provider
  read/write/clear cycle against an in-memory `FlutterSecureStorage` fake.
  `setUpAll(AppLogger.bootstrap)` initialises the singleton before the
  role-provider helpers fire their `[RoleProvider] set role` /
  `[RoleProvider] hydrate` lines (instrumented in Phase 02).
- `mobile/docs/logging-plan/check_pii.sh` (Phase 06) — run from any cwd
  to grep `lib/` for bearer tokens, Stripe `pi_…` / `seti_…` /
  `sk_(live|test)_…` identifiers, and raw `print(` / `debugPrint(`
  calls. Exits 0 on a clean tree, 2 on a finding. Currently clean.
- Phase 11 device test matrix lives at `docs/verification-checklist.md` —
  derived from `migration-plan/phase-11-verification.md`, organised per
  flow / role / platform (`EN-A` / `AR-A` / `EN-i` / `AR-i`) with
  security, performance, and accessibility sections + an open-issues
  log and a sign-off table. Initial each cell with tester name + date
  on pass.
- Release-build verification (`flutter build apk --release`,
  `flutter build ios --release --no-codesign`) — see
  **Phase 11 QA build setup** below for the Gradle wrapper pin and
  Windows trust store fix that were required to build on a corporate
  AzureAD-joined dev machine. Document build artefact sizes in the
  "Build artefacts" table of the checklist once the build completes.

## Phase 11 QA build setup
Phase 11 verification required three extra tweaks to run a release
build on a corporate-managed Windows 11 machine with SSL interception:

### 1. Gradle wrapper pinned to 8.13-bin
- `android/gradle/wrapper/gradle-wrapper.properties` now uses
  `gradle-8.13-bin.zip` instead of `gradle-8.14-all.zip`.
- Why: the 8.14 distribution was never downloaded on this machine,
  so the wrapper tried to pull it from
  `services.gradle.org/distributions/…` and failed with
  `PKIX path building failed` (corporate SSL interception — the
  proxy's root CA isn't in the JDK's `cacerts`). 8.13-bin was
  already cached by the legacy `mobile-customer/` build, so pointing
  at it sidesteps the fetch entirely. AGP 8.11.1 works fine with
  either version.

### 2. Gradle JVM uses the Windows root cert store
- `android/gradle.properties` adds
  `-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT` to
  `org.gradle.jvmargs`.
- Why: Maven artefacts (AGP transitives, OkHttp, etc.) are pulled
  from `dl.google.com` and `repo.maven.apache.org`; those requests
  also hit the corporate MITM cert which the JDK's default
  `cacerts` doesn't trust, but the Windows cert store does (because
  the machine was joined to AzureAD). The `WINDOWS-ROOT` trust
  store type is a built-in Java 9+ option; no keystore surgery
  needed. Safe on any Windows machine — on non-corporate boxes the
  Windows store has the same public roots as `cacerts`, so behaviour
  is unchanged.

### 3. Core library desugaring for `flutter_local_notifications`
- `android/app/build.gradle.kts` enables
  `isCoreLibraryDesugaringEnabled = true` in `compileOptions` and
  adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
  to `dependencies`.
- Why: `flutter_local_notifications` (used for FCM in-app banners
  via `initLocalNotifications()` in `main.dart`) uses `java.time` on
  `minSdk 21`. Without desugaring, the release build fails with
  `Dependency ':flutter_local_notifications' requires core library
  desugaring to be enabled for :app`. Debug builds succeed because
  they don't run through R8 / Proguard.
- Safe across versions: desugar_jdk_libs 2.1.x is the currently
  recommended line for AGP 8.x. Bump alongside AGP upgrades.

### 4. Payment bypass flag for device testing
- `AppConfig.bypassPayments` — compile-time bool via
  `bool.fromEnvironment('BYPASS_PAYMENTS', defaultValue: false)`.
- When `true`, `BookingNotifier.submitBooking()` skips the Stripe
  path entirely: no `createIntent`, no PaymentSheet, no
  `confirmPayment`. Calls `POST /bookings/jobs` directly and stores
  sentinel strings (`'BYPASSED'`) for `paymentIntentId` +
  `transactionId`. `chargedAmount` is set to `agreedAmount`.
- An orange warning banner — `"QA BUILD — PAYMENTS BYPASSED. Not
  for production."` — is shown at the top of
  `BookingSummaryScreen` whenever the flag is on so testers can't
  ship a bypass build by accident.
- Subscription flow (provider row 29a) is **not** bypassed because
  the backend expects a real Stripe SetupIntent id and can't be
  faked without backend changes.
- Caveat: we haven't yet confirmed whether the backend broadcasts a
  job to providers without a `confirmPayment` call. If provider-side
  rows (16, 17, 18) don't fire against a bypassed job, the backend
  is gating broadcast on payment confirmation and those rows will
  need Stripe test mode (or a backend test flag) to pass. Verify on
  the first QA run.

### QA build + run commands
Release APK (Phase 11 acceptance artefact):
```bash
flutter build apk --release \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_placeholder \
  --dart-define=BYPASS_PAYMENTS=true
```

Day-to-day debug on a connected Samsung:
```bash
flutter run -d <device-id> \
  --dart-define=BYPASS_PAYMENTS=true
```

Without `BYPASS_PAYMENTS=true`, every booking terminates at
PaymentSheet against the placeholder Stripe key and throws
`StripeException` — intentional (prevents accidental live payments
from a misconfigured build).

## Phase 12 store-submission scaffold
Phase 12 shipped the store-facing artefacts and the last mobile-side
compliance bits needed for Apple + Google submission:

- **Listing copy** — `mobile/docs/store-listing-en.md` and
  `mobile/docs/store-listing-ar.md` hold the full EN + AR copy for
  both stores (app name, subtitle, short + long descriptions,
  keywords, data-safety tables, permission rationales, Apple 5.1.2 /
  3.1.1 compliance notes, privacy + terms URLs). Paste verbatim into
  Play Console and App Store Connect.
- **Rejection log** — `mobile/docs/store-rejections.md` is an empty
  template for tracking reviewer rejections with a standard format
  (reviewer note, root cause, fix, resubmit date).
- **Account deletion (Apple 5.1.1(v))** — a destructive red "Delete
  Account" tile on both `CustomerProfileTiles` and
  `ProviderProfileTiles`, a shared `showDeleteAccountDialog` action,
  `AuthNotifier.deleteAccount()`, and `AuthRepository.deleteAccount()`
  which calls `DELETE /customers/me` or `DELETE /providers/me` then
  clears tokens + role and routes to `/welcome`. The mobile side is
  complete; the backend endpoints are a Phase 12 prereq (see below).
- **Runbook** — `migration-plan/phase-12-implementation.md` records
  what landed in the app, the backend hand-off spec (delete endpoints
  + `Auth:ForceUpgradeForLegacyApps` flag), per-store submission
  runbooks (Play appbundle upload, App Store Connect + TestFlight),
  sunset sequencing for the legacy apps, and the analytics-dashboard
  hand-off.

### Backend prereqs before first Apple submission

1. ✅ `DELETE /api/customers/me` + `DELETE /api/providers/me` — shipped
   2026-04-24 on `feat/unified-app`. Anonymises PII via
   `SoftDeletePii()` (sets `FullName="DELETED"`, `Email=null`,
   `Phone="DEL_<shortId>"`, blanks `PasswordHash`, deactivates),
   deletes refresh tokens / OTPs / device tokens / provider location
   rows in a single transaction. Guards against deletion with active
   jobs (`HAS_ACTIVE_JOBS`) or — provider only — an active
   subscription (`HAS_ACTIVE_SUBSCRIPTION`). Contract documented in
   `phase-12-implementation.md` §"Account deletion endpoints".
   Pending deploy to prod (`api.khudmati.app`).
2. ✅ `Auth:ForceUpgradeForLegacyApps` feature flag (default `false`)
   — shipped 2026-04-24 as `LegacyAppUpgradeMiddleware` on
   `feat/unified-app`. See `backend/CLAUDE.md` §"Legacy-app
   force-upgrade gate" and the rollout runbook in
   `phase-12-implementation.md` §"Legacy-app force-upgrade flag".
3. 🟡 `https://khudmati.app/privacy` + `https://khudmati.app/terms` —
   bilingual static pages drafted at `web-landing/public/privacy.html`
   and `/terms.html`; the landing-page Footer now links to them.
   Pending legal review + deploy of `web-landing` to prod.

### Store-submission hand-off (not doable from this machine)
- Play Console upload requires the production signing keystore.
- App Store Connect upload requires Xcode + a Mac + Apple Developer
  Program seat.
- Feature graphic, app icon, and phone screenshots (≥ 2 per locale)
  must be taken from Phase 11 device runs — these aren't in the repo.
- Build commands for the release appbundle / IPA live in
  `phase-12-implementation.md` §"Store submission runbook".

## Backend topology
`AppConfig.backendHost = 'https://api.khudmati.app'` is the **same
host** used by both legacy apps and by the prod web admin. There is
no separate staging environment — local dev points at the same host.
Phase 11 verification therefore runs against production data; create
test accounts that are clearly marked (e.g. phone `+966500000001`)
so they're easy to prune. Any backend change required for Phase 11
/ 12 (the `Auth:ForceUpgradeForLegacyApps` flag, bypass-friendly
broadcast, etc.) must be rolled out to the single prod instance —
plan for a short window and communicate before flipping flags.
