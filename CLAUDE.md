# Khudmati (خدمتي) — Project Root

## What is this?
A two-sided home services marketplace for MENA markets. "Khudmati" means "My Service" in Arabic.
Customers book home services; verified providers accept and fulfill jobs.

## Monorepo layout

| Directory | Stack | Dev port |
|---|---|---|
| `backend/` | .NET 8 modular monolith + PostgreSQL | 5000 |
| `mobile/` | Flutter unified app (Riverpod, GoRouter, Dio) — **in-progress migration** | — |
| `mobile-customer/` | Flutter (Riverpod, GoRouter, Dio) — legacy, being merged into `mobile/` | — |
| `mobile-provider/` | Flutter (Riverpod, GoRouter, Dio) — legacy, being merged into `mobile/` | — |
| `web-landing/` | React + Vite + i18next (AR default / EN fallback) | 3000 |
| `web-admin/` | React + Vite + Tailwind + Zustand | 3001 |
| `web-superadmin/` | React + Vite + Tailwind + Zustand | 3002 |

### Mobile migration (in progress)
The two legacy Flutter apps are being merged into a single role-aware `mobile/`
app on branch `feat/unified-app`. Plan + per-phase prompts live under
`migration-plan/` (see `migration-plan/README.md`). Phase 01 scaffolded
`mobile/`; Phase 02 ported the shared core (theme, l10n, API client, SignalR,
FCM, locale, new `role_provider`); Phase 03 added the role-picker welcome
screen + a role/token-aware GoRouter with placeholder auth/home screens; Phase
04 replaced those placeholders with real role-aware auth (login / register /
OTP / forgot / reset) backed by an `AuthRepository` that branches every call
on `roleProvider` to hit `/auth/customers/*` or `/auth/providers/*`; Phase 05
landed the four shared features under `lib/features/shared/` — chat,
notifications (with role-aware `handleNotificationTap`), profile (shell +
role-branched tile lists + role-aware `PATCH /me`), and a unified rating
bottom sheet with role-branched tag sets. Phase 06 ported the full
customer stack under `lib/features/customer/` — Direction-C home redesign,
5-screen booking wizard (Stripe PaymentSheet + Grok AI "improve with AI"),
live GPS tracking, payment receipt/status, history + job detail, referral,
maintenance reminders, dispute raise — plus `MainScaffoldCustomer` hosting
a `StatefulShellRoute.indexedStack` with 4 tabs (`/customer/home`,
`/customer/history`, `/customer/notifications`, `/customer/profile`) and
the amber-gradient FAB opening `/customer/booking/category`. Phase 07
ported the full provider stack under `lib/features/provider/` — 3-tab
job feed with SignalR live broadcasts and 2-min countdown, onboarding hub
(ID upload + skill tests), active-job status machine with 3 s GPS
broadcast during EnRoute, upload-after-photos before Complete, navigation
page, Stripe Connect earnings + payout onboarding, Power Provider
subscription (Stripe PaymentSheet via SetupIntent), analytics dashboard
(`fl_chart` line/bar/sparkline with 5-min `keepAlive` cache) — plus
`MainScaffoldProvider` hosting a `StatefulShellRoute.indexedStack` with 4
tabs (`/provider/jobs`, `/provider/earnings`, `/provider/notifications`,
`/provider/profile`) and no center FAB. Phase 08 consolidated routing
into one role-aware `GoRouter`, re-namespaced the Phase-5 shared features
under `/customer/*` + `/provider/*` (removed the top-level `/chat`,
`/notifications`, `/profile`, `/profile/edit` shims), added a
provider-tier gate (unverified providers can only reach onboarding /
profile / notifications / chat until they hit `Active`; tier is
persisted to secure storage by `onboardingStatusProvider` and cleared on
logout), and introduced a single `NotificationHandler` in
`lib/core/services/notification_handler.dart` that dispatches both FCM
taps and `khudmati://` custom-scheme deep links
(`khudmati://job/<id>`, `…/reminders`, `…/onboarding`,
`…/referral?ref=CODE`) to role-scoped routes. Android manifest + iOS
`Info.plist` declare the `khudmati` URL scheme; `app_links: ^6.1.4`
streams runtime intents. Phase 09 finalised platform config for
release builds — Android runtime permissions + `<queries>` block,
iOS usage descriptions + `UIBackgroundModes` (fetch / remote-
notification / location), localised launcher name (`Khudmati` EN /
`خدمتي` AR via `values(-ar)/strings.xml` and
`(en|ar).lproj/InfoPlist.strings`), ProGuard/R8 rules for Stripe +
SignalR + Firebase + Play Core (minify + shrinkResources enabled on
the release build type), `String.fromEnvironment('STRIPE_PUBLISHABLE_KEY')`
gating so release builds require `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_…`,
and `flutter_launcher_icons` + `flutter_native_splash` config blocks
in `pubspec.yaml` (source assets drop into `assets/icon/` +
`assets/splash/` once the designer ships finals). Firebase config
files are git-ignored with `.example` placeholders + inline
instructions for `google-services.json` and `GoogleService-Info.plist`.
Phase 10 implemented the hard-cutover strategy (Phase 0 Decision C):
the unified `ApiClient` tags every request with `X-App-Package:
com.khudmati.app` + `X-App-Version`, catches HTTP 426 / `{"error":
"UPGRADE_REQUIRED"}` payloads via a Dio response + error interceptor,
and raises `upgradeRequiredProvider`; the root `MaterialApp.builder`
swaps the whole surface for
`features/migration/presentation/upgrade_required_screen.dart` when
the flag is non-null. `main.dart` fires a one-shot Firebase Analytics
event `migration_opened_new_app` on first launch (persisted via
secure-storage key `migration_first_launch_logged`). The two legacy
apps (`mobile-customer/`, `mobile-provider/`) received minimal final
patches — same headers, a module-level `ValueNotifier<String?>
upgradeRequiredNotifier` flipped by their `ApiClient`, and a
bilingual "Download the new Khudmati app" takeover
(`lib/core/widgets/upgrade_required_screen.dart`) mounted via the
root `MaterialApp.builder`. Backend changes (header sniffing +
`Auth:ForceUpgradeForLegacyApps` feature flag) are specced out in
`migration-plan/phase-10-implementation.md` and scheduled for
Phase 12. Until the migration completes, the two legacy apps remain
the production targets. Phase 11 scaffolded the verification
checklist at `mobile/docs/verification-checklist.md` — a per-row /
per-platform / per-language sign-off sheet derived from the 40-row
test matrix in `migration-plan/phase-11-verification.md`, plus
security, performance, and accessibility sections and an open-issues
log. To make release builds possible on a corporate AzureAD-joined
Windows host with SSL interception, the unified app's Gradle wrapper
was pinned to `gradle-8.13-bin` (already cached from the legacy apps)
and `-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT` was added to
`android/gradle.properties` so the Gradle JVM trusts the corporate
root CA via the Windows cert store. For QA runs without Stripe test
keys, a compile-time `AppConfig.bypassPayments` flag
(`--dart-define=BYPASS_PAYMENTS=true`) short-circuits the booking
flow past PaymentSheet and calls `POST /bookings/jobs` directly;
`BookingSummaryScreen` shows an orange "QA BUILD — PAYMENTS BYPASSED"
banner to prevent accidental production releases. Subscription row
29a is not bypassable (backend expects a real SetupIntent id).
Backend target for Phase 11 is **production** (`api.khudmati.app`) —
there is no separate staging environment, so test data must be
clearly labelled and pruned after the run. Automated baselines on
the unified app are clean (`flutter analyze`: 0 errors / 0 warnings;
`flutter test`: pass). Device-side execution + release builds
(Android APK via the bypass build, iOS IPA via TestFlight once Mac
access is available) are the remaining manual exit criteria before
Phase 12 store submission. Phase 12 scaffolded the store-submission
artefacts: full EN + AR listing copy (`mobile/docs/store-listing-en.md`
+ `store-listing-ar.md`) ready to paste into Play Console and App
Store Connect, a rejection log template (`mobile/docs/store-rejections.md`),
and the in-app account-deletion flow required by Apple 5.1.1(v) +
Google Data Safety — a red "Delete Account" tile on both customer and
provider profile pages, a shared confirmation action
(`features/shared/profile/presentation/delete_account_action.dart`),
`AuthNotifier.deleteAccount()`, and `AuthRepository.deleteAccount()`
calling `DELETE /customers/me` or `DELETE /providers/me`. All three Phase 12 backend / web
prereqs landed in-session:
(1) the `Auth:ForceUpgradeForLegacyApps` middleware specced in
Phase 10 now lives at
`backend/src/Khudmati.API/Middleware/LegacyAppUpgradeMiddleware.cs`,
registered between `UseCors()` and `UseAuthentication()` in
`Program.cs` — flip the `Auth:ForceUpgradeForLegacyApps` appsettings
key (default `false`) once the unified app is live in both stores to
hard-cutover legacy bundles.
(2) bilingual privacy + terms pages are drafted at
`web-landing/public/privacy.html` and `/terms.html` with the
landing-page Footer linking to them (pending legal review + deploy).
(3) `DELETE /api/customers/me` and `DELETE /api/providers/me` shipped
for Apple 5.1.1(v) — `CustomersController.DeleteMe` and
`ProvidersController.DeleteMe` anonymise PII in-place via
`SoftDeletePii()` on the entity (sets `FullName="DELETED"`,
`Email=null`, `Phone="DEL_<shortId>"` to preserve the unique index,
blanks `PasswordHash`), wipe refresh tokens / OTPs / device tokens /
provider location rows in a single transaction, and guard against
deletion with active jobs (`HAS_ACTIVE_JOBS`) or an active provider
subscription (`HAS_ACTIVE_SUBSCRIPTION`). Financial and audit rows
reference the account by FK only so they ride the 7-year tax-law
retention window alongside the anonymised parent. Contract + rollout
runbook + migration docs are in
`migration-plan/phase-12-implementation.md`.
Phase 11 Android release APK built successfully (66.4 MB fat APK —
switch to `flutter build appbundle` for Play Store submission to get
per-ABI slices of ~22 MB each). See `mobile/CLAUDE.md` for details.

Logging plan (separate from the 14-phase migration plan) lives at
`mobile/docs/logging-plan/` — six phases adding structured `talker_flutter`
logging across the unified app. **All six phases are complete**:
- Phase 01 — `AppLogger` + redaction helpers + `/debug/logs` viewer +
  `avoid_print: error` lint; all existing `debugPrint(...)` calls
  migrated.
- Phase 02 — `TalkerDioLogger` (PII-safe, headers + bodies OFF) on the
  `ApiClient`; manual instrumentation on `ApiClient` /
  `SignalRService` / `fcm_service` / `NotificationHandler` /
  `router.redirect` / `role_provider` / `locale_provider`; route push /
  pop / replace via `TalkerRouteObserver` on the root `GoRouter`;
  provider build / dispose / state / errors via
  `TalkerRiverpodObserver` on the root `ProviderContainer`. Added
  `redactUrl` helper that strips token / OTP / password / secret query
  keys (referral `ref=` survives).

Phase 03 — Auth flow + shared features (chat / notifications / profile /
rating). Adds `[AuthRepo]`, `[AuthNotifier]`, `[OtpScreen]`,
`[LoginPage]` / `[RegisterScreen]` / `[ForgotPassword]` /
`[ResetPassword]` / `[WelcomeScreen]` lines to the auth surface;
`[ChatRepo]` / `[ChatNotifier]` / `[ChatScreen]` to chat (no message
text — only lengths); `[NotifRepo]` / `[NotifNotifier]` / `[NotifList]`
to notifications; `[ProfilePage]`, `[ProfileTilesC]` /
`[ProfileTilesP]`, `[EditProfile]`, `[DeleteAccount]` (full Apple
5.1.1(v) trace) to profile; `[RatingRepo]` / `[RatingNotifier]` /
`[RatingSheet]` to rating. Phase 01 redaction helpers (`redactPhone` /
`redactEmail` / `redactOtp` / `redactToken`) are applied at every
PII-touching call site. Validation failures log the reason code
(`reason=validation_failed`, `reason=no_categories`) — never the
offending value. Scope is `mobile/lib/**` only — legacy apps,
backend, and web are out of scope.

Phase 04 — Customer-only stack under `lib/features/customer/**`. T3
treatment for the incident hotspots: `[BookingNotifier]` traces every
state-machine setter and the full Stripe path
(`d 'create intent start' → i 'intent ok' clientSecret=${redactToken(...)}` →
`d 'present sheet' → i 'sheet confirmed' → d 'confirm start' →
i 'confirm ok' jobId=… transactionId=…`); the bypass path emits
`w 'bypass path — no Stripe' reason=qa_build` and the `BYPASSED`
sentinel literally so QA bookings stay distinguishable from real ones.
`[TrackingNotifier]` traces `build`, SignalR `JobStatusChanged` /
`ProviderLocationUpdated` subscriptions, every `i 'status transition'`,
and per-frame `v 'loc update' coords=${redactLatLng(...)} ageMs=…`
(verbose so the 3 s GPS cadence stays off by default). T2 narrow
instrumentation on `[CustomerHome]` (1.2k LOC — only side-effectful
spots: search input, category taps with `source` tag, FAB / rating
banner). Plus `[BookingRepo]`, `[AiRepo]`, `[CategoryScreen]`,
`[JobDescription]` (AI improve trace), `[LocationScreen]` (GPS +
geocode), `[BookingSummary]`, `[BookingConfirm]`, `[TrackingPage]`,
`[PaymentRepo]`, `[PaymentReceipt]`, `[PaymentStatus]`,
`[HistoryPage]`, `[JobDetail]`, `[ReferralRepo]`,
`[ReferralNotifier]`, `[ReferralScreen]`, `[RemindersRepo]`,
`[RemindersNotifier]`, `[RaiseDispute]`. Stripe redaction rule:
`clientSecret` always passes through `redactToken(...)`; raw
`paymentMethod` / `customerId` / Stripe response objects are never
logged. Maps coordinates always pass through `redactLatLng(...)` (2
decimal places, ≈ 1.1 km).

Phase 05 — Provider-only stack under `lib/features/provider/**`. T3
treatment for the four incident hotspots:
`[JobDetailNotifier]` traces the 2-min job countdown
(`i 'countdown start' seconds=120 → v 'tick' remaining=… → w 'expired'`)
and accept / reject (`d 'accept start' → i 'accept ok' / e 'accept failed'`);
`[ActiveJobNotifier]` traces every status transition with
`i 'status' from=… to=… source=signalr|advance_api`, the EnRoute
GPS broadcast (`i 'gps broadcast start' intervalMs=3000`,
`v 'gps push' coords=${redactLatLng(...)}` per frame,
`i 'gps broadcast stop' reason=arrived|disposed|restart`), and GPS
errors with `e 'gps failed'`; `[SkillTest]` traces the full session
(`d 'init' → i 'session start' sessionId=… total=… → d 'answer'
q=… optionId=… → d 'submit start' → i 'session ok' score=…
passed=…` or `w 'session failed cooldown' nextRetryAt=…`);
`[Subscription]` + `[SubscriptionNotifier]` trace the Stripe
SetupIntent path
(`i 'subscribe start' → d 'setup intent start' → i 'setup intent ok'
clientSecret=${redactToken(secret)} → d 'sheet present' →
i 'sheet confirmed' → i 'activate ok' status=Active`) with
`StripeException` always logging `e 'sheet failed'
code=${error.code.name}` plus a softer
`w 'sheet cancelled'` for `FailureCode.Canceled`. T2 instrumentation
on `[JobRepo]`, `[JobFeedNotifier]` (SignalR `NewJobAvailable`),
`[JobFeedScreen]` (tab change), `[JobDetailScreen]`,
`[ActiveJobDetail]` (action taps), `[UploadAfterPhotos]`
(`d 'advance blocked' reason=no_after_photo` gate),
`[OnboardingApi]` (with `i 'tier bumped' from=… to=…` for the
persisted-tier change that drives the next router redirect),
`[OnboardingHub]`, `[IdUploadScreen]`, `[ProviderNav]` (Geolocator
permission + position trace), `[EarningsRepo]`, `[EarningsNotifier]`,
`[PayoutStatus]` (Stripe Connect onboarding URL launch via
`redactUrl(...)`), `[SubscriptionRepo]`, `[AnalyticsRepo]`,
`[AnalyticsNotifier]` (parallel `Future.wait` fetch trace).
Same Stripe redaction rule: every `clientSecret` /
`paymentMethodId` passes through `redactToken(...)`; the derived
SetupIntent id is safe to log in full. Provider-tier gate
logging is split: Phase 02's router redirect still logs the
`/provider/onboarding` deflection; Phase 05's
`OnboardingApi.tier bumped` line traces the underlying tier change.

Phase 06 — Polish & release. Hardens the logging stack for
production: `AppLogger.v` / `d` / `i` early-return when
`kReleaseMode` so `verbose` / `debug` / `info` emit nothing in a
release APK / IPA (only `w` / `e` / `c` survive). A new
`CrashlyticsSink` (`mobile/lib/core/logging/crashlytics_sink.dart`)
mirrors `error` (`fatal: false`) and `critical` (`fatal: true`)
log lines to Firebase Crashlytics — wired by
`AppLogger.attachCrashlytics(...)` from `main.dart` only when
`firebaseReady && kReleaseMode`. `FlutterError.onError` and
`PlatformDispatcher.instance.onError` are installed before any
other init so a Stripe / Firebase / deep-link bootstrap throw
lands in the same Talker history as runtime errors. The
`/debug/logs` `GoRoute` (and the redirect-guard short-circuit
on `/debug/`) are wrapped in `if (kDebugMode)` so the in-app
viewer is unreachable in release builds. Adds
`firebase_crashlytics: ^3.5.0` to `pubspec.yaml` and a CI-ready
PII sweep script at `mobile/docs/logging-plan/check_pii.sh`
(grep for bearer tokens, Stripe `pi_…` / `seti_…` /
`sk_(live|test)_…` identifiers, and raw `print(` /
`debugPrint(` outside `redact.dart`; exits 0 on a clean tree,
2 on a finding).

## Brand
- Blue: `#1B4F72` — primary brand, backgrounds, buttons
- Amber: `#F39C12` — CTA, highlights
- Fonts: Cairo (Arabic), Inter (English)
- UI is RTL-first (Arabic is the primary language)

## Database
PostgreSQL 16. Schema-per-module:
- `customers.*` — customer accounts, OTPs, refresh tokens, referral_codes (one per customer), referral_uses (referrer↔referee link, Pending→Completed), customer_credits (platform credit wallet)
- `providers.*` — provider accounts, OTPs, refresh tokens, provider locations, document_submissions, skill_test_questions, skill_test_sessions, tier_history, rating_stats; `providers.providers` has `is_suspended`, `suspended_reason`, `suspended_at`, `suspended_by` columns (Feature #14); `providers.subscription_plans` (admin-managed plan config: monthly_fee, commission_rate, priority_delay_seconds); `providers.provider_subscriptions` (Active|PastDue|Cancelled|Paused, stripe_subscription_id, current_period_start/end)
- `admins.*` — admin accounts, refresh tokens, platform_config (single-row platform settings), audit_log (super admin action history)
- `bookings.*` — jobs, job photos, job rejections, ratings, job_status_history, disputes
- `payments.*` — transactions, provider_stripe_accounts
- `public.*` — notifications (shared), contact_inquiries (landing page contact form submissions), reminder_rules (admin-configured reminder interval per category; `interval_days`, `is_active`), scheduled_reminders (per-customer scheduled reminders — status: Scheduled|Sent|Dismissed|Snoozed|Booked)

Start DB (local dev): `cd backend && docker-compose up -d postgres`

## Auth
JWT with 4 distinct audiences: `customer`, `provider`, `admin`, `superadmin`.
Every protected endpoint validates the audience claim. See `backend/CLAUDE.md` for details.

## Prompt history
Implementation prompts live in the project root as `01-authentication.md`, etc.
Each prompt covers one vertical feature slice across all platforms.

## Implemented features
| # | Prompt file | Feature |
|---|---|---|
| 01 | `01-authentication.md` | Customer, provider, admin auth (OTP, JWT, refresh tokens) |
| 02 | `02-customer-booking-flow.md` | Customer booking flow — 5 screens, photo upload, reference number |
| 03 | `03-provider-job-acceptance.md` | Provider job feed, accept/reject, 2-min countdown, SignalR, background expiry |
| 05 | `05-payments.md` | On-platform payments — Stripe PaymentSheet, 24h hold, Connect payouts, commission |
| 06 | `06-post-job-rating.md` | Post-job rating — binary thumbs up/down, optional tags, provider aggregate stats |
| 07 | `07-provider-onboarding-verification.md` | Provider onboarding — ID upload, skill tests, tier system, admin verification |
| 08 | `08-live-gps-tracking.md` | Live GPS tracking — provider location broadcasts every 3s during EnRoute, customer sees live map |
| 09 | `09-in-app-chat.md` | In-app chat — per-job messaging via SignalR, persisted to DB, chat FAB with unread badge |
| 11 | `11-post-job-photo-requirement.md` | Post-job photo requirement — provider uploads after-photos before completing, customer sees before/after split |
| 12 | `12-admin-jobs-management.md` | Admin jobs management — paginated job list with filters, job detail drawer, force cancel (Pending/Accepted only) |
| 13 | `13-admin-disputes.md` | Admin disputes — customer raises dispute on Paid jobs, admin reviews queue, approve refund (Stripe) or reject, SignalR notifications to both parties |
| 14 | `14-admin-provider-management.md` | Admin provider management — paginated provider list with stats/filters, provider detail drawer (rating stats, tier history, documents), suspend/reinstate with SignalR notifications |
| 15 | `15-super-admin.md` | Super admin panel — admin account CRUD (create/update/revoke), platform config (commission rate, job timeout, etc.), financial ledger with date-range filtering, full audit log |
| 16 | `16-web-landing-page.md` | Web landing page — live platform stats (GET /api/landing/stats), working contact form (POST /api/landing/contact → public.contact_inquiries), scroll-aware header, i18n for all sections, SEO meta tags + Open Graph |
| 17 | `17-referral-system.md` | Double-sided referral programme — unique 8-char code per customer, referee gets 15% discount on first booking, referrer gets 20 SAR credit after referred customer's first paid booking; credit auto-applied at checkout (oldest-expiry-first); deep link `khudmati.app/join?ref=CODE` pre-fills signup |
| 18 | `18-subscription-power-provider-tier.md` | Power Provider monthly subscription — 99 SAR/month (configurable), 10% commission vs 15% standard, 30-second job priority head-start via `providers-power` SignalR group; Stripe Subscriptions + webhook lifecycle; provider app subscription screen; admin overview + super admin plan config |
| 19 | `19-maintenance-reminders.md` | Maintenance reminders — rule-based scheduling (IRemindersScheduler + AI stub behind feature flag), hourly background worker dispatches push notifications, customer can snooze (≤30 days) or dismiss; admin configures interval per category; reminder card in customer app with "احجز الآن" deep link back to booking flow |
| 20 | `20-provider-analytics-dashboard.md` | Provider analytics dashboard — earnings summary with line chart + period-over-period %, job stats (completed count, acceptance rate, top categories bar chart), rating breakdown (positive %, tag frequency, sparkline of last 10); 5-min local cache; all three API calls parallelised via Future.wait; fl_chart for charts |
| 21 | `21-Grok_AI_Booking_Description_Helper.md` | Grok AI description helper — "Improve with AI" button on job description screen; backend proxies to `api.x.ai` (grok-3-mini); feature-flagged via `Features:AiAssist`; toggled on in `appsettings.Development.json` |
| 23 | `23-customer-app-gaps.md` | Customer app UX gaps — Maintenance Reminders screen (#19 wired end-to-end), logout fix (clears tokens → `/welcome`), auth startup fetchMe (real user name/phone on profile header), Edit Profile screen (`PATCH /api/customers/me`), Help & Support URL launch, Coming Soon snackbar for Addresses/Payments/Notifications tiles, home search filter, category tap pre-select (bypasses category picker), notifications tap shows view-job snackbar, payment receipt shows chargedAmount + discount breakdown, history/detail `moving`+`other` categories + unknown ID fallback |
| 24 | `24-provider-app-bugs-routing.md` | Provider app critical bug fixes — logout clears tokens (→ `/welcome`), onboarding routes registered (`/onboarding`, `/onboarding/id-upload`, `/onboarding/skill-test`), FCM handler uses `addPostFrameCallback`, API client refresh path fixed (`/auth/providers/refresh`), `NavigationPage` wired to real job GPS + real `JobDetail` coordinates (no more hardcoded Beirut pin), empty-state refresh button enabled, distance unit localised (`km`/`كم`), hardcoded 4.8 rating removed from profile |
| 25 | `25-provider-app-l10n-profile-cleanup.md` | Provider app L10n cleanup & UX — all hardcoded Arabic strings replaced with `s.<key>` l10n calls (chat widgets, rating bottom sheet); all profile tiles wired to real actions (Edit→`/profile/edit`, Verification→`/onboarding`, Payment→`/payout-status`, Work Hours/Notifications→Coming Soon snackbar, Help→url_launcher); new `EditProfileScreen` (`PATCH /api/providers/me`); Completed Jobs tab wired to real API (`GET /api/providers/me/jobs?status=Paid` with net amount from payments join); legacy stub files deleted (`jobs_page.dart`, `job_detail/`); notifications pagination awareness added |
| 26 | `26-provider-app-subscription-analytics.md` | Provider app Subscription & Analytics — `SubscriptionScreen` (`GET/POST/DELETE /api/providers/me/subscription`, Stripe PaymentSheet via SetupIntent, SignalR events: SubscriptionActivated/Cancelled/PaymentFailed); `AnalyticsScreen` (earnings line chart, job stats grid + bar chart, rating sparkline via `fl_chart`; 3 parallel API calls via `Future.wait`, 5-min `keepAlive` cache, period chips); backend controllers `ProviderSubscriptionController` + `ProviderAnalyticsController` added; `ProviderSubscription` entity extended with `StripeCustomerId`, `CancelsAtPeriodEnd`, `CancelledAt`; `flutter_stripe ^10.1.1` + `fl_chart ^0.68.0` + `intl ^0.19.0` added to pubspec; run `backend/add-subscription-screen.sql` before deploying |

## web-admin status
All pages are fully wired to real APIs (no mock data). See `web-admin/CLAUDE.md` for route and API layer details.

| Page | Status |
|---|---|
| `/dashboard` | ✅ Live — `GET /api/admin/dashboard` |
| `/jobs` | ✅ Live — real API, detail drawer, force-cancel |
| `/providers` | ✅ Live — two tabs: All Providers (tier filter) + Verification Queue (approve/reject drawer) |
| `/customers` | ✅ Live — search/filter/pagination, Deactivate action |
| `/disputes` | ✅ Live — two-panel queue, approve refund / reject |
| `/subscriptions` | ✅ Live — `GET /api/admin/subscriptions` |
| `/reminder-rules` | ✅ Live — inline edit + create, `GET/POST/PUT /api/admin/reminder-rules` |
| `/settings` | ✅ Live (read-only) — `GET /api/admin/platform-config`; changes require Super Admin |

### ⚠️ Before deploying
Run `backend/add-admin-features.sql` against PostgreSQL **before** deploying the backend.
Creates `providers.provider_subscriptions` and `public.reminder_rules` tables required by the new admin endpoints.

## Key conventions
- Never return OTP values in API responses
- Error codes are SCREAMING_SNAKE_CASE strings in the `error` field (e.g. `"INVALID_CREDENTIALS"`)
- All API responses follow `{ "success": bool, "data": {...} }` or `{ "success": false, "error": "CODE" }`
- All EF entity configurations live in `Program.cs` via `AppDbContext.AdditionalModelConfiguration` (never in `Khudmati.Shared`)
- Repositories use `_context.Set<T>()` — no DbSet properties on AppDbContext
- Rating: binary thumbs up/down + optional positive tags — stored in `bookings.ratings`
- Provider aggregate stats in `providers.rating_stats` — updated on every customer→provider rating
- Rating window: 48 hours after job reaches `Paid` status
- Provider verification tiers: Unverified → PhoneVerified → IdVerified → SkillTested → Active
- Only Active tier providers join `providers-available` SignalR group and see jobs
- Tier history logged in `providers.tier_history` on every change
- Skill tests: 10 questions per category, 7/10 to pass, 24h cooldown on failure
- Job photos have `photo_type` column (`"before"` | `"after"`); API returns them as `beforePhotoUrls` / `afterPhotoUrls`; provider must upload ≥1 after-photo before `InProgress → Completed` transition is allowed
- Referral codes: 8-char uppercase alphanumeric, auto-generated on customer registration, stored in `customers.referral_codes`; one code per customer, one referral use per new customer
- Referee discount: 15% off first booking; referrer credit: 20 SAR; credit validity: 365 days; self-referral blocked by phone number comparison
- Customer credits auto-applied at checkout (oldest-expiry-first); credit applied cannot exceed booking total; referral credit awarded only after referred customer's first job reaches `Paid` status
- Error codes: `REFERRAL_NOT_FOUND`, `REFERRAL_ALREADY_USED`, `REFERRAL_SELF_REFERRAL`
- Subscription tiers: Standard (free, 15% commission) vs Power Provider (99 SAR/month configurable, 10% commission, 30 s job head-start)
- Commission rate resolution: check `providers.provider_subscriptions` for Active row → use `subscription_plans.commission_rate`; stored in `payments.transactions.commission_rate_applied`
- Priority broadcast: fire `NewJobAvailable` to `providers-power` group first; after `plan.priority_delay_seconds`, fire to `providers-available` only if job is still `Pending`
- Stripe webhook events handled: `invoice.payment_succeeded`, `invoice.payment_failed`, `customer.subscription.deleted`
- Grace period: PastDue providers retain Power Provider benefits for 3 days before revert to Standard
- Error codes: `PROVIDER_NOT_ACTIVE`, `ALREADY_SUBSCRIBED`, `PAYMENT_METHOD_INVALID`, `STRIPE_ERROR`
- Maintenance reminders: one reminder scheduled per job when it reaches `Paid` status; silently skipped if no rule exists for the category; duplicate suppression: no new reminder if customer was reminded for same category within last 14 days
- Reminder status lifecycle: Scheduled → Sent (by hourly worker) → Dismissed | Snoozed | Booked; snooze max 30 days
- Error codes: `REMINDER_NOT_FOUND`, `REMINDER_ALREADY_DISMISSED`, `SNOOZE_DAYS_EXCEEDED`
- `IRemindersScheduler` interface in `Modules/Customers/Application/Services/`; `RuleBasedRemindersScheduler` (V1) + `AiRemindersScheduler` (stub); toggled by `Features:AiScheduling` appsettings flag
- Analytics endpoints: `GET /api/providers/me/analytics/earnings?period=`, `GET /api/providers/me/analytics/jobs?period=`, `GET /api/providers/me/analytics/ratings`; all return zero/null values (never 404) for providers with no data; `changePercent` and `positiveRatePct` are nullable
- Analytics periods: `Last7Days` | `Last30Days` | `Last3Months` | `AllTime`; chart truncation unit is day/week/month depending on period
- Grok AI: `POST /api/ai/improve-description` (CustomerOnly); feature-flagged via `Features:AiAssist`; `Grok:ApiKey` config key; model `grok-3-mini`; returns `503` when flag off, `502` on Grok failure; enabled locally via `appsettings.Development.json`
- Location screen (customer app): NO GPS permission — map defaults to Riyadh, user drags pin, taps "Confirm Location" (`s.locConfirm`) for reverse geocoding; no `geolocator` calls in `LocationScreen`
- App language defaults to English (`localeProvider` = `Locale('en')`); toggle EN↔AR via welcome screen button or profile page Language tile; all screens in both `mobile-customer` (~20 screens) and `mobile-provider` (~21 screens) are fully localised via `S.of(ref)` / `S.read(ref)`
- Customer profile page: logout calls `AuthNotifier.logout()` → clears tokens → navigates to `/welcome`; Edit Profile calls `PATCH /api/customers/me`; Help & Support opens `https://khudmati.app/#contact` in external browser; Addresses/Payments/Notifications show "Coming Soon" snackbar
- Customer app home: category grid tap pre-selects via `bookingNotifierProvider.setCategory()` and navigates directly to `/booking/description`; search `StateProvider` filters grid client-side
- Payment receipt shows `chargedAmount` (actual charged) with referral/credit breakdown rows; falls back to `agreedAmount`
- FCM notification handler in `lib/core/services/notification_handler.dart`; `MAINTENANCE_REMINDER` type routes to booking flow + marks reminder as `Booked` (best-effort)
- Provider app logout: `AuthNotifier.logout()` → clears tokens via `AuthRepository.logout()` → navigates to `/welcome`; token refresh path is `POST /api/auth/providers/refresh` (matches both `ApiClient` interceptor and `AuthRepository`)
- Provider `NavigationPage`: uses `activeJobNotifierProvider(jobId)` for real job data; customer destination pin = `LatLng(job.latitude, job.longitude)` (amber); provider pin = device GPS via `Geolocator.getCurrentPosition()` (blue); `job.district` shown as address label; `InProgress` advance button pushes to after-photos screen

## SignalR events (server → client)
| Event | Fired when | Group | Payload |
|---|---|---|---|
| `NewJobAvailable` | Job created | `providers-available` | `{ jobId, categoryId, distanceKm, ... }` |
| `VerificationStatusChanged` | Admin approves/rejects documents | `provider-{providerId}` | `{ newTier, status, message }` |
| `ProviderLocationUpdated` | Provider sends location during EnRoute | `customer-{customerId}` | `{ jobId, latitude, longitude, timestamp }` |
| `NewChatMessage` | Chat message sent | `customer-{customerId}` or `provider-{providerId}` (other party only) | `{ id, jobId, senderId, senderType, text, sentAt }` |
| `DisputeOpened` | Customer raises a dispute | `provider-{providerId}` | `{ jobId, disputeId, complaint }` |
| `DisputeResolved` | Admin resolves a dispute | `customer-{customerId}` and `provider-{providerId}` | `{ disputeId, jobId, action, message }` (action: `approve_refund` or `reject`) |
| `AccountSuspended` | Admin suspends a provider | `provider-{providerId}` | `{ reason }` |
| `AccountReinstated` | Admin reinstates a provider | `provider-{providerId}` | `{}` |
| `SubscriptionActivated` | Provider subscribes to Power Provider | `provider-{providerId}` | `{ plan, commissionRate, currentPeriodEnd }` |
| `SubscriptionPaymentFailed` | Stripe invoice payment fails | `provider-{providerId}` | `{ retryDate }` |
| `SubscriptionCancelled` | Stripe subscription deleted webhook fires | `provider-{providerId}` | `{ endsAt }` |

## SignalR groups
- `providers-available` — all online Active tier providers (broadcast new jobs after Priority delay)
- `providers-power` — Active tier providers with an Active subscription (receive `NewJobAvailable` 30 s ahead of standard providers)
- `customer-{customerId}` — personal per-customer group (location updates, payment notifications)
- `provider-{providerId}` — personal per-provider group (verification status, payment notifications, subscription events)
- `job-{jobId}` — per-job group (joined manually by client)
