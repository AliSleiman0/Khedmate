# Phase 04 — Customer features

**Depends on:** Phase 01, 02, 03.

Customer-side stack under `lib/features/customer/`. Booking + Stripe +
tracking are the incident hotspots — they get full T3 treatment. Everything
else tiers down.

## Files touched

### Booking (the 5-screen wizard + Stripe + AI)

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/customer/booking/data/booking_repository.dart` | T2 | 73 | POST /bookings/jobs, createIntent, AI helper |
| `lib/features/customer/booking/data/ai_repository.dart` | T1 | — | POST /ai/improve-description — log req + result length only |
| `lib/features/customer/booking/presentation/booking_provider.dart` | T3 | 264 | Category / desc / location / Stripe state machine + bypass flag |
| `lib/features/customer/booking/presentation/category_screen.dart` | T1 | — | tap → setCategory |
| `lib/features/customer/booking/presentation/job_description_screen.dart` | T2 | 457 | AI "Improve with AI" call — log start/ok/failed |
| `lib/features/customer/booking/presentation/location_screen.dart` | T2 | 272 | Drag-pin + reverse geocode |
| `lib/features/customer/booking/presentation/booking_summary_screen.dart` | T3 | 574 | Submit (Stripe or bypass) — full trace |
| `lib/features/customer/booking/presentation/booking_confirmation_screen.dart` | T1 | 486 | Reference number display |

### Home

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/customer/home/home_page.dart` | T2 | 1214 | Search filter, category tap, pending-rating banner, reminder card |

Although 1.2k LOC, most of it is UI. Only **instrument the side-effectful
parts**: search state, category pre-select, reminder banner tap, pending-
rating banner tap. 8–10 log lines total.

### Tracking / payments / history

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/customer/tracking/presentation/job_tracking_provider.dart` | T3 | 132 | SignalR `ProviderLocationUpdated` subscription |
| `lib/features/customer/tracking/presentation/tracking_page.dart` | T2 | 864 | Map + status polling + rating CTA |
| `lib/features/customer/payments/data/payment_repository.dart` | T1 | 54 | GET receipt |
| `lib/features/customer/payments/presentation/payment_provider.dart` | T1 | — | |
| `lib/features/customer/payments/presentation/payment_receipt_screen.dart` | T1 | — | |
| `lib/features/customer/payments/presentation/payment_status_screen.dart` | T1 | — | |
| `lib/features/customer/history/presentation/history_page.dart` | T1 | — | |
| `lib/features/customer/history/presentation/job_detail_page.dart` | T2 | 417 | Before/after photos + dispute CTA |

### Referral / reminders / dispute

| Path | Tier | LOC | Focus |
|---|---|---|---|
| `lib/features/customer/referral/data/referral_repository.dart` | T1 | — | |
| `lib/features/customer/referral/presentation/referral_provider.dart` | T2 | 105 | Apply code → `REFERRAL_SELF_REFERRAL` etc. |
| `lib/features/customer/referral/presentation/referral_screen.dart` | T1 | 528 | share tap, copy tap |
| `lib/features/customer/reminders/data/reminders_repository.dart` | T1 | 80 | list / snooze / dismiss |
| `lib/features/customer/reminders/presentation/reminders_provider.dart` | T2 | 68 | snooze / dismiss / deep-link back into booking |
| `lib/features/customer/reminders/presentation/reminders_screen.dart` | T1 | — | |
| `lib/features/customer/dispute/presentation/raise_dispute_screen.dart` | T2 | 372 | POST /disputes + SignalR wait |

## Per-file log blueprint

### `booking_provider.dart` (T3)

Tag: `BookingNotifier`. The state machine reason is that customers drop out
here more than anywhere else, and the Stripe branch is the #1 source of
silent failures.

- `setCategory(id)` — `d 'setCategory' id=$id`.
- `setDescription(text)` — `d 'setDescription' len=${text.length}`.
- `setLocation(latLng, addr)` — `d 'setLocation' coords=${redactLatLng(lat,lng)}`.
- `submitBooking()` branch:
  - `i 'submit start' category=… amount=… bypass=${AppConfig.bypassPayments}`.
  - **Bypass path**: `w 'bypass path — no Stripe' reason=qa_build`,
    `i 'api start' endpoint=/bookings/jobs` → `i 'api ok' jobId=$id` /
    `e 'api failed' code=$code`.
  - **Normal path**: `d 'create intent start'` → `i 'intent ok'
    clientSecret=${redactToken(secret)}` → `d 'present sheet'` →
    `i 'sheet confirmed'` / `w 'sheet cancelled'` / `e 'sheet failed'` →
    `d 'confirm start'` → `i 'confirm ok' jobId=$id` / `e 'confirm failed'`.
- Every `StripeException` — `e 'stripe exception'` with `error.code` +
  `error.message` (the Stripe SDK's own message is safe — it doesn't contain PII).

### `job_tracking_provider.dart` (T3)

Tag: `TrackingNotifier`.

- `build(jobId)` — `d 'build' jobId=$jobId`.
- `d 'signalr subscribe' event=ProviderLocationUpdated jobId=$jobId`.
- For each incoming update — `v 'loc update' jobId=$jobId coords=${redactLatLng(...)} ageMs=$age`.
  (Uses `verbose` because these arrive every 3 seconds.)
- `i 'status transition' from=$old to=$new` on job-status changes.
- `ref.onDispose` — `d 'unsubscribed'`.

### `referral_provider.dart` (T2)

Tag: `ReferralNotifier`.

- `load()` — `d 'load start'`, `i 'load ok' code=$code credits=$n` / `e 'load failed'`.
- `apply(code)` — `d 'apply start' code=$code`, `i 'apply ok'` or
  `w 'apply failed' code=REFERRAL_SELF_REFERRAL|REFERRAL_ALREADY_USED|REFERRAL_NOT_FOUND`.

### `reminders_provider.dart` (T2)

Tag: `RemindersNotifier`.

- `load()` — `d 'load start'`, `i 'load ok' count=$n`.
- `snooze(id, days)` — `d 'snooze start' id=$id days=$d`,
  `i 'snooze ok'` / `w 'snooze failed' code=SNOOZE_DAYS_EXCEEDED`.
- `dismiss(id)` — `d 'dismiss start' id=$id`,
  `i 'dismiss ok'` / `w 'dismiss failed' code=REMINDER_ALREADY_DISMISSED`.
- `bookFromReminder(id)` — `i 'deep link to booking' id=$id category=$cat`.

### `raise_dispute_screen.dart` (T2)

Tag: `RaiseDispute`.

- `d 'open' jobId=$jobId`.
- `d 'submit start' reasonLen=${text.length}`.
- `i 'submit ok' disputeId=$id` / `w 'submit failed' code=$code`.
- The resulting SignalR `DisputeOpened` event is logged by the tracking /
  notifications side as usual.

### `home_page.dart` (T2) — narrow instrumentation

Tag: `CustomerHome`.

- `d 'search changed' len=${query.length}` (no value).
- `d 'category tap' id=$id bypassPicker=true` right before navigating to
  `/customer/booking/description`.
- `d 'reminder card tap' id=$id`.
- `d 'rating banner tap' jobId=$jobId`.
- `d 'fab tap'` for the central booking FAB.

## Stripe logging — extra caution

The one place where a careless log statement can leak real payment data.
Rules:

- Never log `intent.clientSecret` raw — always `redactToken(...)`.
- Never log `paymentMethod`, `customerId`, or any Stripe object wholesale.
- Stripe `StripeException` messages are safe (SDK-controlled strings).
- For the bypass path, log the sentinel string `BYPASSED` explicitly so
  post-hoc analysis doesn't confuse a QA transaction with a real one.

## Acceptance criteria

- Running a full booking from `category_screen` to `booking_confirmation_screen`
  with `BYPASS_PAYMENTS=true` produces a clean T3 trace in the log viewer:
  roughly 18–22 lines, every screen transition visible.
- Running the same flow with Stripe test mode produces ~28 lines, with the
  6 Stripe-specific steps visible between `d 'create intent start'` and
  `i 'confirm ok'`.
- Disputes / referrals / reminders each produce a 3–5 line trace on the
  happy path.
- Tracking subscription, with 10 GPS updates, produces 10 `v` lines — they
  do **not** appear at the default `debug` level (only when you flip
  verbose on in Talker's settings).
- No Stripe client-secret string appears in full anywhere in the log buffer.
