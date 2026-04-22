# Phase 06 — Port Customer-Only Features

## Goal
Port all customer-exclusive functionality from `mobile-customer/` into `mobile/lib/features/customer/`, and build the customer-side `MainScaffold` with its 4-tab bottom nav.

## Why this phase
After this phase, a real customer can use the unified app end-to-end — book a job, pay, track, rate, review history — without ever touching the old customer app.

## Pre-requisites
- Phase 05 complete (chat, notifications, profile, rating wired)
- Customer test account with payment method
- Backend running

## Scope

### 1. Port Home
**Source:** `mobile-customer/lib/features/home/presentation/home_page.dart`

This is the Direction C redesign (~1000 lines) already done. Copy entire directory:
- `home_page.dart` — `_TopBar`, `_AskSection`, `_ContextChips`, `_BrowseSection`, `_FeatureTile`, `_CategoryTile`, `_BookAgainSection`, `_ReferralStrip`
- Private providers: `_searchQueryProvider`, `_recentJobsProvider`

Target: `mobile/lib/features/customer/home/home_page.dart`

No structural changes — just update imports.

### 2. Port Booking (5-screen wizard)
**Source:** `mobile-customer/lib/features/booking/`

Files:
- `category_screen.dart`
- `description_screen.dart` — includes Grok AI "Improve with AI" button, `POST /ai/improve-description`
- `location_screen.dart` — flutter_map + manual pin drag (note: `desiredAccuracy:` uses geolocator 11.x API; already fixed)
- `summary_screen.dart` — price + referral discount breakdown
- `confirmation_screen.dart` — polls job status (Searching/Accepted/Expired)
- `booking_provider.dart` — `BookingNotifier` orchestrating state + Stripe payment
- `booking_repository.dart`

Target: `mobile/lib/features/customer/booking/**`

### 3. Port Payments
**Source:** `mobile-customer/lib/features/payments/`

Files:
- `payment_receipt_screen.dart` — shows `chargedAmount` + referral/credit breakdown
- `payment_status_screen.dart`
- `payment_repository.dart` — Stripe PaymentSheet integration
- `payment_provider.dart`

Target: `mobile/lib/features/customer/payments/**`

### 4. Port History
**Source:** `mobile-customer/lib/features/history/`

Files:
- `history_page.dart`
- `job_detail_page.dart` — before/after photo split, dispute CTA
- `history_provider.dart`

Target: `mobile/lib/features/customer/history/**`

### 5. Port Live Tracking
**Source:** `mobile-customer/lib/features/tracking/`

- `tracking_page.dart` — live map with provider (amber) + customer (blue) pins
- `tracking_provider.dart` — subscribes to `ProviderLocationUpdated` SignalR event
- Uses `distance_utils.dart` from core

Target: `mobile/lib/features/customer/tracking/**`

### 6. Port Referral
**Source:** `mobile-customer/lib/features/referral/`

- `referral_screen.dart` — code display + native share sheet
- `referral_repository.dart` — `GET /customers/me/referral`
- Apply code at signup — already handled in Phase 4's register screen

Target: `mobile/lib/features/customer/referral/**`

### 7. Port Maintenance Reminders
**Source:** `mobile-customer/lib/features/reminders/`

- `reminders_screen.dart` — list with snooze/dismiss/Book Now
- `reminders_repository.dart` — `PATCH /customers/me/reminders/{id}`

Target: `mobile/lib/features/customer/reminders/**`

Deep link: FCM `MAINTENANCE_REMINDER` tap → `/booking/category` (already in `notification_handler.dart` from Phase 2)

### 8. Port Dispute
**Source:** `mobile-customer/lib/features/dispute/`

- `raise_dispute_screen.dart` — 20–1000 char textarea
- `dispute_repository.dart` — `POST /bookings/jobs/{id}/dispute`

Target: `mobile/lib/features/customer/dispute/**`

### 9. Build `MainScaffoldCustomer`
**Source:** `mobile-customer/lib/widgets/main_scaffold.dart` (already has amber-gradient FAB)

Target: `mobile/lib/widgets/main_scaffold_customer.dart`

Tabs (unchanged from current customer app):
1. Home → `/customer/home`
2. History → `/customer/history`
3. Notifications → `/customer/notifications`
4. Profile → `/customer/profile`

Center FAB: amber gradient, 58px, white ring — tapping navigates to `/customer/booking/category`.

### 10. Update router — customer branch
Under `StatefulShellRoute.indexedStack` for customer role:
```
/customer/home
/customer/history
/customer/history/:jobId
/customer/notifications
/customer/profile
/customer/profile/edit
/customer/booking/category
/customer/booking/description
/customer/booking/location
/customer/booking/summary
/customer/booking/confirmation
/customer/tracking/:jobId
/customer/payment/receipt
/customer/payment/status/:jobId
/customer/chat/:jobId
/customer/referral
/customer/reminders
/customer/dispute/raise
```

Remove placeholder customer home from Phase 3.

Shared routes (`/profile`, `/notifications`, `/chat/:jobId`) from Phase 5 move under `/customer/...` and `/provider/...` — they're thin wrappers that forward to the shared widget.

## Files to create
- `mobile/lib/features/customer/home/**`
- `mobile/lib/features/customer/booking/**` (~8 files)
- `mobile/lib/features/customer/payments/**` (~4 files)
- `mobile/lib/features/customer/history/**` (~3 files)
- `mobile/lib/features/customer/tracking/**` (~2 files)
- `mobile/lib/features/customer/referral/**` (~2 files)
- `mobile/lib/features/customer/reminders/**` (~2 files)
- `mobile/lib/features/customer/dispute/**` (~2 files)
- `mobile/lib/widgets/main_scaffold_customer.dart`

## Files to modify
- `mobile/lib/app/router.dart` — add ~18 customer routes under shell

## Files to delete
- `mobile/lib/features/customer/placeholder_home.dart`

## Verification
End-to-end test as a customer:
1. Log in → lands on `/customer/home` (Direction C redesign)
2. Search filter works, category grid tap preselects and navigates to description
3. Complete full booking: category → description (with AI improve) → location (drag pin) → summary (with referral code) → confirmation
4. Job picked up by provider (use old provider app as counterpart) → live tracking shows pin moving
5. Provider completes → rating bottom sheet appears
6. Submit rating → job appears in history
7. Job shows before/after photos in detail view
8. Raise dispute → appears in admin panel
9. Referral screen shows code + share works
10. Reminders screen shows scheduled reminders, snooze + dismiss work
11. Deep link from FCM `MAINTENANCE_REMINDER` routes to booking flow

## Exit criteria
- [ ] All 11 verification steps pass on a real Android device
- [ ] Bottom nav tabs switch without state loss
- [ ] Amber FAB opens booking flow
- [ ] No console errors during any flow
- [ ] `flutter analyze` clean (info-level lints OK)
- [ ] Commit: `feat(mobile): port customer-only features`

## Rollback
- Revert commit. Old customer app still works.
