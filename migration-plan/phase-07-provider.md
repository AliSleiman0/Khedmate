# Phase 07 — Port Provider-Only Features

## Goal
Port all provider-exclusive functionality from `mobile-provider/` into `mobile/lib/features/provider/`, and build the provider-side `MainScaffold` with its 4-tab bottom nav.

## Why this phase
After this phase, a real provider can use the unified app end-to-end — complete onboarding, receive job broadcasts, accept, navigate, complete with after-photos, collect earnings, subscribe to Power Provider, view analytics.

## Pre-requisites
- Phase 06 complete (customer side works end-to-end)
- Provider test accounts at various tiers: Unverified, PhoneVerified, IdVerified, Active
- Stripe Connect test account + subscription test payment method
- Backend running

## Scope

### 1. Port Job Feed & Job Flow
**Source:** `mobile-provider/lib/features/jobs/`

Files:
- `job_feed_screen.dart` — 3 tabs: Available / Active / Completed
- `job_detail_screen.dart`
- `active_job_detail_screen.dart` — in-progress state, advance button
- `upload_after_photos_screen.dart` — required before `InProgress → Completed`
- `job_feed_provider.dart` — subscribes to `NewJobAvailable` via SignalR (`providers-available` group)
- `active_job_provider.dart` — for the active GPS tracking
- `jobs_repository.dart` — `GET /provider/jobs`, accept/reject endpoints, status transitions

Target: `mobile/lib/features/provider/jobs/**`

Note the 2-minute countdown UI for accept/reject.

### 2. Port Onboarding / Verification
**Source:** `mobile-provider/lib/features/onboarding/`

Files:
- `onboarding_hub_screen.dart` — 3-step stepper (ID upload → skill test → wait for verification)
- `id_upload_screen.dart` — passport/ID front + back, document upload to S3 via backend
- `skill_test_screen.dart` — 10-question quiz per category, 7/10 to pass, 24h cooldown
- `onboarding_provider.dart` — tier progression state
- `onboarding_repository.dart` — `GET /providers/me/onboarding`, `POST /providers/me/documents`, `POST /providers/me/skill-test/start`, `POST /providers/me/skill-test/submit`

Target: `mobile/lib/features/provider/onboarding/**`

Router guard: if provider's tier != Active on login, force redirect to `/provider/onboarding`.

### 3. Port Navigation (Live GPS)
**Source:** `mobile-provider/lib/features/navigation/`

Files:
- `navigation_page.dart` — flutter_map, non-interactive; provider pin (device GPS) + customer pin (job latitude/longitude)
- `navigation_provider.dart` — broadcasts location every 3s via SignalR during EnRoute status
- `active_job_notifier.dart` — used to read current job

Target: `mobile/lib/features/provider/navigation/**`

Background location requires `ACCESS_BACKGROUND_LOCATION` on Android — declared in Phase 9.

### 4. Port Earnings
**Source:** `mobile-provider/lib/features/earnings/`

Files:
- `earnings_page.dart` — summary, transaction history
- `payout_status_screen.dart` — Stripe Connect onboarding link if not set up
- `earnings_repository.dart` — `GET /providers/me/earnings`

Target: `mobile/lib/features/provider/earnings/**`

### 5. Port Analytics
**Source:** `mobile-provider/lib/features/analytics/`

Files:
- `analytics_screen.dart` — 3 sections: earnings line chart, job stats bar chart + grid, rating sparkline + breakdown
- `analytics_provider.dart` — 3 parallel API calls via `Future.wait`, 5-min `keepAlive` cache
- `analytics_repository.dart` — `GET /providers/me/analytics/earnings?period=`, `/jobs?period=`, `/ratings`

Target: `mobile/lib/features/provider/analytics/**`

Uses `fl_chart` from pubspec (added in Phase 1).

### 6. Port Subscription (Power Provider)
**Source:** `mobile-provider/lib/features/subscription/`

Files:
- `subscription_screen.dart` — plan card (99 SAR/month), Stripe PaymentSheet via SetupIntent, SignalR listeners for `SubscriptionActivated`/`Cancelled`/`PaymentFailed`
- `subscription_repository.dart` — `GET/POST/DELETE /providers/me/subscription`

Target: `mobile/lib/features/provider/subscription/**`

On subscription active, app joins `providers-power` SignalR group for 30-second job head-start.

### 7. Build `MainScaffoldProvider`
**Source:** `mobile-provider/lib/widgets/main_scaffold.dart`

Target: `mobile/lib/widgets/main_scaffold_provider.dart`

Tabs (unchanged from current provider app):
1. Jobs → `/provider/jobs`
2. Earnings → `/provider/earnings`
3. Notifications → `/provider/notifications`
4. Profile → `/provider/profile`

No center FAB (providers don't create anything).

### 8. Update router — provider branch
Under `StatefulShellRoute.indexedStack` for provider role:
```
/provider/jobs
/provider/job-detail/:jobId
/provider/active-job/:jobId
/provider/active-job/:jobId/after-photos
/provider/navigation/:jobId
/provider/earnings
/provider/payout-status
/provider/notifications
/provider/profile
/provider/profile/edit
/provider/chat/:jobId
/provider/onboarding
/provider/onboarding/id-upload
/provider/onboarding/skill-test
/provider/subscription
/provider/analytics
```

Remove placeholder provider home from Phase 3.

### 9. Wire SignalR group joins
On login as provider (after `fetchMe` returns):
1. Join `provider-{providerId}` personal group (always)
2. If tier == Active → join `providers-available`
3. If subscription.status == Active → join `providers-power`

These joins happen once, on app start after auth, in `signalr_service.dart`.

## Files to create
- `mobile/lib/features/provider/jobs/**` (~7 files)
- `mobile/lib/features/provider/onboarding/**` (~5 files)
- `mobile/lib/features/provider/navigation/**` (~3 files)
- `mobile/lib/features/provider/earnings/**` (~3 files)
- `mobile/lib/features/provider/analytics/**` (~3 files)
- `mobile/lib/features/provider/subscription/**` (~2 files)
- `mobile/lib/widgets/main_scaffold_provider.dart`

## Files to modify
- `mobile/lib/app/router.dart` — add ~16 provider routes under shell
- `mobile/lib/core/services/signalr_service.dart` — add group-join logic

## Files to delete
- `mobile/lib/features/provider/placeholder_home.dart`

## Verification
End-to-end as a provider:
1. Register as new provider with service categories → OTP → lands on `/provider/onboarding`
2. Upload ID documents → submits, status → `PhoneVerified`
3. Take skill test → passes → tier → `SkillTested`
4. Admin approves → receive `VerificationStatusChanged` SignalR → tier → `Active`
5. Lands on `/provider/jobs` (Available tab)
6. New job broadcast by customer → appears in feed with 2-min countdown
7. Accept job → moves to Active tab
8. Mark EnRoute → navigation page opens, location broadcasts every 3s (verify customer side on old customer app or unified customer session)
9. Complete job flow: InProgress → upload after-photo → Completed
10. Customer pays → job status `Paid` → rating sheet
11. Earnings page shows net amount
12. Analytics tab: charts load, switch period chips work
13. Subscribe to Power Provider with test card → `providers-power` group joined → confirmation SignalR event received
14. Next new job arrives 30 seconds before it does on a non-Power provider

## Exit criteria
- [ ] All 14 verification steps pass on a real Android device
- [ ] SignalR groups correctly joined on login, cleared on logout
- [ ] Background location permission works for navigation broadcasts
- [ ] Stripe subscription PaymentSheet succeeds with test card
- [ ] Charts render in both LTR (English) and RTL (Arabic) modes
- [ ] `flutter analyze` clean
- [ ] Commit: `feat(mobile): port provider-only features`

## Rollback
- Revert commit. Old provider app still works.
