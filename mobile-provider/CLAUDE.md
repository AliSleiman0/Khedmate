# mobile-provider — Flutter Provider App

## Run
```bash
flutter pub get
flutter run
```
API base URL: `http://10.0.2.2:5000/api` (Android emulator). Change to `http://localhost:5000/api` for iOS.

## Purpose
App for service providers (سباكة، كهرباء، تنظيف، نجارة، دهان) to receive, accept, and fulfill job requests.
Distinct from the customer app — separate JWT audience (`provider`), separate auth endpoints.

## Architecture
Feature-first folder structure:
```
lib/
├── app/
│   ├── app.dart
│   ├── router.dart       # Auth guard redirects to /jobs on login
│   └── theme.dart
├── core/
│   ├── api/api_client.dart           # Refresh endpoint: /providers/auth/refresh
│   ├── services/signalr_service.dart # HubConnection with JWT token factory + auto-reconnect
│   └── constants/colors.dart
└── features/
    ├── auth/
    │   ├── data/auth_repository.dart       # /providers/auth/* endpoints
    │   └── presentation/
    │       ├── auth_provider.dart           # AuthNotifier with ProviderUser model
    │       ├── welcome_screen.dart          # "أنا مزود خدمة" primary CTA
    │       ├── register_screen.dart         # Includes service category multi-select
    │       ├── otp_screen.dart
    │       └── login_page.dart              # On success → /jobs
    ├── jobs/
    │   ├── data/job_repository.dart         # JobSummary + JobDetail models, 5 HTTP methods; uploadAfterPhotos()
    │   └── presentation/
    │       ├── job_feed_provider.dart       # JobFeedNotifier (AsyncNotifier<List<JobSummary>>)
    │       ├── job_detail_provider.dart     # JobDetailNotifier (FamilyAsyncNotifier<JobDetailState, String>)
    │       ├── job_feed_screen.dart         # 3-tab layout (Available / Active / History)
    │       ├── job_detail_screen.dart       # Map + countdown ring + accept/reject
    │       ├── active_jobs_screen.dart      # Accepted jobs list with status chips
    │       └── upload_after_photos_screen.dart  # Photo grid (max 5), upload after-photos before completing job
    ├── navigation/          # Map navigation to customer location
    ├── onboarding/
    │   ├── data/onboarding_api_service.dart   # POST documents, GET/POST skill test
    │   ├── domain/
    │   │   ├── onboarding_status.dart         # VerificationTier enum, OnboardingStatus model
    │   │   └── skill_test.dart                # SkillTest, SkillTestQuestion, SkillTestResult models
    │   ├── providers/onboarding_providers.dart # onboardingStatusProvider (FutureProvider)
    │   └── presentation/
    │       ├── onboarding_hub_screen.dart     # 3-step progress stepper
    │       ├── id_upload_screen.dart          # Camera/gallery image picker, document type selector
    │       └── skill_test_screen.dart         # Category selection, 10-question quiz with timer
    ├── earnings/
    │   ├── data/earnings_repository.dart    # getEarningsSummary(), getMyTransactions(), getStripeOnboardingUrl()
    │   └── presentation/
    │       ├── earnings_provider.dart        # EarningsSummaryNotifier, EarningsTransactionsNotifier
    │       ├── earnings_page.dart            # Summary cards, Stripe Connect banner, transaction list
    │       └── payout_status_screen.dart     # Balance cards + Stripe Connect onboarding flow
    ├── subscription/
    │   ├── data/subscription_repository.dart   # GET/POST/DELETE /api/providers/me/subscription
    │   └── presentation/
    │       ├── subscription_provider.dart       # SubscriptionNotifier (AsyncNotifier<SubscriptionState?>)
    │       └── subscription_screen.dart         # باقة المزود المتميز — feature comparison table, subscribe CTA, cancel flow
    ├── analytics/
    │   ├── data/analytics_repository.dart      # GET /api/providers/me/analytics/* endpoints; 5-min local cache per period
    │   ├── domain/
    │   │   ├── earnings_analytics.dart          # EarningsAnalytics model + ChartDataPoint
    │   │   ├── job_stats.dart                   # JobStats model + TopCategory
    │   │   ├── rating_analytics.dart            # RatingAnalytics model + RecentRating
    │   │   └── analytics_period.dart            # AnalyticsPeriod enum: last7Days|last30Days|last3Months|allTime
    │   └── presentation/
    │       ├── analytics_provider.dart          # AnalyticsNotifier (AsyncNotifier<AnalyticsDashboardState>); setPeriod() refreshes all three sections in parallel via Future.wait
    │       └── analytics_screen.dart            # التحليلات — period chips, earnings line chart, job stats 2x2 grid + bar chart, rating breakdown + sparkline
    └── profile/
```

## Provider-specific auth differences
- Register payload includes `serviceCategories: string[]` — at least one required
- Available categories: `سباكة`, `كهرباء`, `تنظيف`, `نجارة`, `دهان`
- JWT audience: `provider` (enforced server-side on all `/api/providers/*` and `/api/provider/jobs/*` endpoints)
- Refresh token endpoint: `POST /api/providers/auth/refresh`

## Provider Verification & Onboarding
### Tier System
```
Unverified → PhoneVerified → IdVerified → SkillTested → Active
```
- **OnboardingHubScreen** triggered automatically after login if `verificationTier != Active`
- **ID Upload**: Front + back image upload (NationalId/Passport/ResidencePermit), max 5MB per file
- **Skill Test**: 10 multiple-choice questions per category, 7/10 to pass, 24h cooldown on failure
- **Real-time notification**: SignalR `VerificationStatusChanged` event when admin approves/rejects documents
- Only **Active** tier providers can see jobs in the feed

### Onboarding Screens
1. **OnboardingHubScreen** — 3-step vertical stepper showing progress (ID ✓, Skill ⏳, Phone ✓)
2. **IdUploadScreen** — Camera/gallery picker, document type dropdown, front/back upload areas
3. **SkillTestScreen** — Category selection → 10 questions with progress bar → pass/fail result with celebration/retry message

## Key provider flow
1. Provider registers with phone + service categories → OTP verification
2. After login: if `verificationTier != Active` → navigate to `/onboarding`, else → `/jobs`
3. Complete onboarding steps → reach **Active** tier → can now see job feed
4. Job feed connects SignalR on init, subscribes `NewJobAvailable`, sends GPS location every 30s
5. Job detail (`/jobs/:id`) shows 2-minute countdown ring (green >60s, amber 30–60s, red <30s)
6. On accept: server locks job with SELECT FOR UPDATE, returns job detail with provider info
7. On expire: detail screen auto-navigates back to feed
8. **Live GPS Tracking (EnRoute status)**: When provider taps "I'm on my way" (status → EnRoute), `ActiveJobNotifier` starts broadcasting GPS location every 3 seconds to `/tracking/jobs/{jobId}/location`. Broadcasting stops automatically when status changes to InProgress or job completes.
9. **Post-Job Photos (InProgress status)**: When provider taps “إنهاء الخدمة” while job is `InProgress`, the app navigates to `/active-job/:jobId/after-photos` instead of advancing directly. The `UploadAfterPhotosScreen` uploads ≥1 after-photo via `POST /api/providers/jobs/{jobId}/after-photos`, then triggers the `InProgress → Completed` advance.
10. After job Completed → `PaymentReleased` SignalR event → provider receives net payout to Stripe Connect account

## State management patterns
- `JobFeedNotifier extends AsyncNotifier<List<JobSummary>>` — connects SignalR hub, prepends new jobs from `NewJobAvailable` event, calls `UpdateProviderLocationCommand` on startup.
- `JobDetailNotifier extends FamilyAsyncNotifier<JobDetailState, String>` — parameterized by `jobId`. Starts `Timer.periodic` countdown; on `secondsRemaining == 0` or server `410` response, sets state to expired.
- `ActiveJobNotifier extends FamilyAsyncNotifier<JobDetail, String>` — subscribes to `JobStatusChanged` events and manages automatic GPS location broadcasting:
  - Starts `Timer.periodic` (3s interval) when job status = `EnRoute`, sending location via `POST /tracking/jobs/{jobId}/location`
  - Stops timer when status transitions to `InProgress` or any other status
  - Handles location permission denial gracefully (job continues without tracking)
  - Uses `geolocator` package with `LocationAccuracy.high`

## Real-time (SignalR)
`lib/core/services/signalr_service.dart` — `HubConnectionBuilder` connecting to `/hubs/jobs`:
- `accessTokenFactory` reads JWT from `FlutterSecureStorage`
- `withAutomaticReconnect()` configured
- Provider JWT `aud` claim causes server to auto-join `providers-available` AND `provider-{userId}` groups
- Active Power Provider subscribers also join `providers-power` group — they receive `NewJobAvailable` 30 s before standard providers
- `JobFeedNotifier` subscribes `NewJobAvailable` on hub connect
- `PaymentReleased` event fires on `provider-{providerId}` group when 24h hold expires and Stripe Transfer completes

## Routing
| Route | Screen |
|---|---|
| `/welcome` | WelcomeScreen |
| `/login` | LoginPage |
| `/register` | RegisterScreen |
| `/otp` | OtpScreen |
| `/onboarding` | OnboardingHubScreen (3-step stepper) |
| `/onboarding/id-upload` | IdUploadScreen |
| `/onboarding/skill-test` | SkillTestScreen |
| `/jobs` | JobFeedScreen (3 tabs) |
| `/jobs/:id` | JobDetailScreen |
| `/active-job/:jobId/after-photos` | UploadAfterPhotosScreen |
| `/payout-status` | PayoutStatusScreen |
| `/subscription` | SubscriptionScreen |
| `/analytics` | AnalyticsScreen |

## UI conventions
- Same RTL-first, Cairo font, AppColors rules as customer app
- Welcome screen tagline: "بوابة مزودي الخدمة"
- Welcome screen shows `Image.asset('assets/images/logo.png', height: 130)` above the app name (32pt). Asset must be placed at `assets/images/logo.png` (declared in pubspec).
- On login success: navigate to `/jobs` (not `/home`)
- Pulsing amber dot on job cards where `secondsRemaining < 60`
- Job detail map uses `flutter_map` in non-interactive mode (just shows pin)

## Locale / Language
`lib/core/providers/locale_provider.dart` — `StateProvider<Locale>` defaulting to `Locale('en')`. Toggle between EN↔AR at runtime.
- **Welcome screen**: language toggle button at top right
- **Profile page**: Language tile (between ساعات العمل and الإشعارات) calls `ref.read(localeProvider.notifier).state = ...` to toggle; `ProfilePage` is a `ConsumerWidget`
- `lib/core/l10n/app_strings.dart` — `S.of(ref)` type-safe string accessor

## Key dependencies
| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | Token persistence |
| `pinput` | OTP digit input boxes |
| `signalr_netcore` | Real-time job feed updates |
| `flutter_map` | Map display (OpenStreetMap tiles) |
| `latlong2` | Coordinate types for flutter_map |
| `geolocator` | GPS for location updates sent to server |
| `image_picker` | After-photo selection from gallery/camera (also used in onboarding ID upload) |
| `url_launcher` | Open Stripe Connect Express onboarding URL in browser |
| `fl_chart` | Line chart (earnings over time), bar chart (top categories), sparkline (rating trend) |

## Subscription (Feature #18)
- **SubscriptionScreen** (`features/subscription/presentation/subscription_screen.dart`): hero amber gradient card, feature comparison table (Standard vs Power Provider), subscribe CTA opens Stripe PaymentSheet via existing `flutter_stripe` integration; subscribed state shows status card with next billing date + commission rate + cancel button
- **Profile screen**: amber "مزود متميز ⭐" badge beside provider name when subscribed; "إدارة الاشتراك" tile navigates to SubscriptionScreen
- **SubscriptionNotifier**: `AsyncNotifier<SubscriptionState?>` — `build()` calls `GET /api/providers/me/subscription`; `subscribe(paymentMethodId)` calls `POST`; `cancel()` calls `DELETE` + shows confirmation dialog
- Cancel confirmation: destructive dialog before calling cancel API; benefits persist until `current_period_end`
- SignalR events received on `provider-{providerId}` group: `SubscriptionActivated`, `SubscriptionPaymentFailed`, `SubscriptionCancelled`

## Analytics Dashboard (Feature #20)
- **AnalyticsScreen** (`features/analytics/presentation/analytics_screen.dart`): period chips ("٧ أيام" / "٣٠ يوم" / "٣ أشهر" / "الكل"); Section 1 — hero card (brand blue) with net earnings + period-over-period % arrow + pending badge + `fl_chart` line chart; Section 2 — 2×2 stat cards grid + horizontal bar chart for top 5 categories; Section 3 — rating score card + amber positive tag chips + red negative tag chips + sparkline of last 10 ratings
- **AnalyticsNotifier**: `AsyncNotifier<AnalyticsDashboardState>` — `setPeriod()` sets `AsyncLoading` then calls `_load()`; `_load()` parallelises all three API calls via `Future.wait([getEarnings, getJobStats, getRatingStats])`
- **5-minute local cache**: `AnalyticsRepository` stores last response + timestamp per period; returns cached data if called within 5 minutes for the same period
- **Navigation**: "التحليلات" accessible from provider app bottom navigation or profile menu
- **Empty/zero states**: if provider has no jobs, all metrics show 0; `positiveRatePct` is `null` when `totalRatings == 0` — UI shows "لا توجد تقييمات بعد" instead of 0%; `changePercent` is `null` when previous period earnings = 0
- **Period chips disabled** while loading — shimmer/skeleton on each section card
- All monetary values display in Arabic numerals with "ر.س" suffix
