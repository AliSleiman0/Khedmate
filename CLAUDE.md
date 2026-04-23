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
FCM, locale, new `role_provider`). Until the migration completes, the two
legacy apps remain the production targets. See `mobile/CLAUDE.md` for details.

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
