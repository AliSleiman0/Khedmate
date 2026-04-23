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
role-scoped route.

## Identity
- Package ID / bundle ID: `com.khudmati.app` (both Android + iOS)
- Display name: "Khudmati"
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
  Notifications → `/customer/notifications`, Help → `https://khudmati.app/#contact`.
- Provider tiles: Edit → `/provider/profile/edit`, Verification →
  `/provider/onboarding`, Payment → `/provider/payout-status`, Subscription
  → `/provider/subscription`, Analytics → `/provider/analytics`, Work Hours
  (Coming Soon), Language toggle, Notifications (Coming Soon), Help.
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
| 09–13 | Platform config, user migration, store submission, etc. | ⏳ queued |

## Verification
- `flutter analyze` → 0 issues.
- `flutter test` → `test/widget_test.dart` exercises the role_provider
  read/write/clear cycle against an in-memory `FlutterSecureStorage` fake.
- Device/emulator smoke test (launch + locale persistence round-trip) pending
  manual verification per phase exit criteria.
