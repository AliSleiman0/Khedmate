# Feature: Provider Job Acceptance

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend: Flutter (mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisite: Feature #01 (Authentication) and Feature #02 (Customer Booking Flow) must be implemented first

## Goal
When a customer creates a job, nearby available providers get notified and see it in their job feed. A provider can accept or reject within a 2-minute window. If no action is taken, the job auto-rejects and the customer is notified. This closes the core transaction loop — a job goes from `Pending` to `Accepted`.

## Platforms Affected
- [x] Provider Mobile App (Flutter)
- [x] Backend (.NET 8)
- [x] Customer Mobile App (Flutter) — receives real-time update when job is accepted
- [ ] Admin Panel — feature #12
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **provider**, I want to see new job requests in my feed so I can decide whether to accept them.
- As a **provider**, I want to accept or reject a job within 2 minutes so the customer isn't left waiting.
- As a **customer**, I want to be notified in real-time when a provider accepts my job so I know help is on the way.
- As the **system**, I want to auto-reject jobs that no provider accepts within the timeout window and notify the customer.

---

## Provider App Screens

### Screen 1: Job Feed (`lib/features/jobs/presentation/job_feed_screen.dart`)
- Purpose: The provider's home screen — shows all available (Pending) jobs in their area
- UI:
  - Page title: "الطلبات المتاحة" (Available Jobs)
  - List of job cards, newest first
  - Each card shows: service category icon + name, distance from provider ("٢.٣ كم"), address (neighbourhood/district only — not full address for privacy), time since posted ("منذ ٥ دقائق"), a pulsing amber dot if posted < 2 minutes ago
  - Empty state: "لا توجد طلبات متاحة حالياً" with a refresh icon
  - Pull-to-refresh
  - Real-time: new jobs appear at the top automatically via SignalR (no manual refresh needed)
  - Tab bar at bottom: "المتاحة" (Available) | "الجارية" (Active) | "المنجزة" (Completed)

### Screen 2: Job Detail / Accept Screen (`lib/features/jobs/presentation/job_detail_screen.dart`)
- Purpose: Provider reviews the job and decides to accept or reject within 2 minutes
- UI:
  - Top section: category icon + name, posted time
  - Customer description (full text)
  - Map showing job location pin (non-interactive, just a static view) — use `flutter_map`
  - District/neighbourhood name + estimated distance from provider
  - Photo thumbnails if customer attached photos (tappable to expand)
  - **Countdown timer** — large, prominent, centered: counts down from 2:00 to 0:00
    - Green when > 60 seconds
    - Amber when 30–60 seconds
    - Red when < 30 seconds, pulsing
    - Label: "الوقت المتبقي للقبول" (Time remaining to accept)
  - Two buttons at the bottom, full width:
    - "قبول الطلب" (Accept Job) — brand blue background, white text
    - "رفض" (Reject) — outlined, grey text
  - On timeout (0:00): both buttons disabled, show "انتهت مدة القبول" (Acceptance window expired), auto-navigate back to feed after 2 seconds
  - On accept success: navigate to Active Job screen (stub for now — feature #04)
  - On reject: navigate back to feed

### Screen 3: Active Jobs Tab (`lib/features/jobs/presentation/active_jobs_screen.dart`)
- Purpose: Shows jobs the provider has accepted and is currently working on
- UI: Simple list of accepted jobs with status chip (Accepted / EnRoute / InProgress)
- Tapping navigates to job detail (read-only view for now — navigation/tracking is feature #04 and #08)
- Empty state: "لا توجد طلبات جارية"

---

## State Management

### Job Feed Provider (`lib/features/jobs/presentation/job_feed_provider.dart`)
```dart
@riverpod
class JobFeedNotifier extends _$JobFeedNotifier {
  @override
  Future<List<JobSummary>> build() async {
    // Connect to SignalR and listen for new jobs
    _subscribeToNewJobs();
    return ref.read(jobRepositoryProvider).getAvailableJobs();
  }

  void _subscribeToNewJobs() {
    ref.read(signalRServiceProvider).on('NewJobAvailable', (data) {
      final newJob = JobSummary.fromJson(data);
      state = AsyncData([newJob, ...state.value ?? []]);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).getAvailableJobs(),
    );
  }
}
```

### Job Detail Provider (`lib/features/jobs/presentation/job_detail_provider.dart`)
```dart
@riverpod
class JobDetailNotifier extends _$JobDetailNotifier {
  Timer? _countdownTimer;
  static const _timeoutSeconds = 120;

  @override
  Future<JobDetailState> build(String jobId) async {
    final job = await ref.read(jobRepositoryProvider).getJobById(jobId);
    _startCountdown(job.secondsRemaining);
    ref.onDispose(() => _countdownTimer?.cancel());
    return JobDetailState(job: job, secondsRemaining: job.secondsRemaining);
  }

  void _startCountdown(int initialSeconds) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.value;
      if (current == null) return;
      if (current.secondsRemaining <= 1) {
        _countdownTimer?.cancel();
        state = AsyncData(current.copyWith(secondsRemaining: 0, isExpired: true));
      } else {
        state = AsyncData(current.copyWith(
          secondsRemaining: current.secondsRemaining - 1,
        ));
      }
    });
  }

  Future<void> acceptJob() async {
    final job = state.value?.job;
    if (job == null) return;
    _countdownTimer?.cancel();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await ref.read(jobRepositoryProvider).respondToJob(job.id, 'accept');
        return state.value!.copyWith(isAccepted: true);
      },
    );
  }

  Future<void> rejectJob() async {
    final job = state.value?.job;
    if (job == null) return;
    _countdownTimer?.cancel();
    await ref.read(jobRepositoryProvider).respondToJob(job.id, 'reject');
  }
}
```

---

## API Endpoints

### GET /api/providers/jobs/available
- Auth: Provider JWT (audience = `provider`)
- Query params: `page=1&pageSize=20`
- Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "jobId": "uuid",
        "referenceNumber": "KH-20240403-0001",
        "categoryId": "plumbing",
        "categoryName": "سباكة",
        "distanceKm": 2.3,
        "district": "Hamra",
        "secondsRemaining": 87,
        "postedAt": "ISO8601",
        "hasPhotos": true
      }
    ],
    "totalCount": 5
  }
}
```
- Business rules:
  - Return only jobs with status = `Pending` and `expires_at > now()`
  - Calculate distance from provider's last known location (use `providers.locations` table)
  - Only return jobs within 10km radius in V1 (no smart matching yet)
  - Ordered by `created_at DESC`

### GET /api/providers/jobs/{jobId}
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "jobId": "uuid",
    "referenceNumber": "string",
    "categoryId": "string",
    "categoryName": "string",
    "description": "string",
    "latitude": 0.0,
    "longitude": 0.0,
    "district": "string",
    "distanceKm": 0.0,
    "photoUrls": ["string"],
    "secondsRemaining": 87,
    "postedAt": "ISO8601",
    "status": "Pending"
  }
}
```
- Business rules:
  - If job status is not `Pending` or `expires_at < now()`, return `410 Gone` with error `"JOB_NO_LONGER_AVAILABLE"`
  - `secondsRemaining` = `EXTRACT(EPOCH FROM (expires_at - now()))` — always fresh from DB

### POST /api/providers/jobs/{jobId}/respond
- Auth: Provider JWT
- Request: `{ "action": "accept" | "reject" }`
- Response (accept):
```json
{
  "success": true,
  "data": {
    "jobId": "uuid",
    "status": "Accepted",
    "providerId": "uuid"
  }
}
```
- Business rules:
  - If `action = "accept"`:
    - Check job is still `Pending` and `expires_at > now()` — return `410 "JOB_NO_LONGER_AVAILABLE"` if not
    - Transition job: `Pending → Accepted` via state machine on `Job` entity
    - Set `provider_id` on the job
    - Set `accepted_at = now()`
    - Log `JobAcceptedEvent` domain event
    - Fire SignalR event `JobAccepted` to customer (see Real-time section)
    - Return updated job
  - If `action = "reject"`:
    - Log rejection in `bookings.job_rejections` (provider_id, job_id, rejected_at)
    - Do NOT change job status — it stays `Pending` for other providers
    - Return `200` with `{ "success": true }`
  - Race condition: if two providers accept simultaneously, use a DB transaction with `SELECT FOR UPDATE` on the job row — first writer wins, second gets `410`

### POST /api/providers/location
- Auth: Provider JWT
- Request: `{ "latitude": 0.0, "longitude": 0.0 }`
- Response: `{ "success": true }`
- Business rules: Upsert provider's current location in `providers.locations`. Called every 30 seconds from the provider app when the app is in foreground. Used to calculate distance in job feed queries.

---

## Data Model Changes

```sql
-- Add to bookings.jobs
ALTER TABLE bookings.jobs
  ADD COLUMN expires_at TIMESTAMPTZ,        -- set to created_at + 2 minutes on insert
  ADD COLUMN accepted_at TIMESTAMPTZ;

-- Update trigger: set expires_at on insert
-- In application layer: set expires_at = now() + interval '2 minutes' in CreateJobCommand

-- Track rejections (used later for provider analytics)
CREATE TABLE bookings.job_rejections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES bookings.jobs(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL,
    rejected_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Provider last known location
CREATE TABLE providers.locations (
    provider_id UUID PRIMARY KEY,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Auto-Reject Background Job

Use a hosted service (`IHostedService`) that runs every 30 seconds and expires jobs nobody accepted:

```
Modules/Bookings/Khudmati.Modules.Bookings/Infrastructure/BackgroundJobs/JobExpiryService.cs
```

Logic:
1. Query all jobs where `status = 'Pending'` AND `expires_at < now()`
2. For each: transition to a new status `Expired` (add `Expired` to `JobStatus` enum)
3. Log `JobExpiredEvent` domain event
4. Fire SignalR event `JobExpired` to customer — see Real-time section
5. Wrap each expiry in a try/catch — one failure must not stop the others

> Note: `Expired` is a terminal state. It does NOT transition further. Customer will need to rebook (V2 will auto-repost).

---

## Real-time / SignalR Events

All events go through `JobHub` in `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`.

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `NewJobAvailable` | Job created (feature #02 `CreateJobCommandHandler`) | All providers in radius group | `{ jobId, categoryName, distanceKm, district, secondsRemaining }` |
| `JobAccepted` | Provider accepts | Customer (personal group `customer-{customerId}`) | `{ jobId, providerName, providerPhone, providerRating }` |
| `JobExpired` | Auto-expiry service runs | Customer (personal group `customer-{customerId}`) | `{ jobId, message: "لم يتم قبول طلبك، يرجى المحاولة مرة أخرى" }` |

### SignalR Groups
- On provider connect: join group `providers-available` (if provider is active/online)
- On customer connect: join group `customer-{customerId}`
- On provider accept: leave `providers-available` (they're now busy)

### Flutter SignalR Service (`lib/core/services/signalr_service.dart`)
Use the `signalr_netcore` package. Connect on app launch after authentication. Reconnect automatically on disconnect.

---

## Customer App Changes (real-time update)

In `mobile-customer`, the Booking Confirmation screen (feature #02) should already be listening to SignalR. Add handling for the `JobAccepted` event:

- File: `lib/features/booking/presentation/booking_confirmation_screen.dart`
- When `JobAccepted` received for the current `jobId`:
  - Replace the "جاري البحث..." spinner with a success state
  - Show provider name + estimated arrival
  - Change CTA to "تتبع المزود" (Track Provider) — navigates to tracking screen (feature #04, stub for now)
- When `JobExpired` received:
  - Show "لم يتم قبول طلبك" (Your job wasn't accepted)
  - Show "إعادة المحاولة" (Try Again) button — calls the same booking API to repost the job

---

## Backend File Structure

```
Modules/Bookings/Khudmati.Modules.Bookings/
├── Application/
│   ├── Commands/
│   │   ├── RespondToJobCommand.cs             ← accept or reject
│   │   ├── RespondToJobCommandHandler.cs
│   │   ├── RespondToJobCommandValidator.cs
│   │   └── ExpireJobCommand.cs                ← used by background service
│   ├── Queries/
│   │   ├── GetAvailableJobsQuery.cs
│   │   └── GetAvailableJobsQueryHandler.cs
│   └── DTOs/
│       ├── AvailableJobSummaryDto.cs
│       └── JobDetailForProviderDto.cs
├── Domain/
│   └── Events/
│       ├── JobAcceptedEvent.cs
│       └── JobExpiredEvent.cs
└── Infrastructure/
    └── BackgroundJobs/
        └── JobExpiryService.cs

Modules/Providers/Khudmati.Modules.Providers/
└── Infrastructure/
    └── Persistence/
        └── ProviderLocationRepository.cs

Khudmati.API/Controllers/
└── Providers/
    └── ProviderJobsController.cs
```

---

## Edge Cases & Validation

- Provider tries to accept an already-accepted job → `410 "JOB_NO_LONGER_AVAILABLE"`
- Two providers accept simultaneously → DB transaction + `SELECT FOR UPDATE` ensures only one wins; loser gets `410`
- Provider not verified (tier < `PhoneVerified`) → `403 "PROVIDER_NOT_VERIFIED"` — do not show jobs in feed
- Provider submits response after countdown hits 0 → `expires_at` check on server rejects it with `410`
- Provider app goes offline mid-countdown → countdown continues client-side; server validates `expires_at` independently
- No providers accept within 2 minutes → background service marks job `Expired`, customer notified via SignalR
- Provider rejects all jobs → no penalty in V1, just log the rejection

---

## Out of Scope (do not implement)
- Smart provider matching (proximity only for V1 — no rating-based or history-based matching)
- Provider earnings calculation — feature #05
- Live GPS tracking during job — feature #08
- Push notifications — feature #10 (SignalR only for now)
- Multiple providers bidding on a job — V2
- Provider reassignment after timeout — customer must rebook in V1

---

## Acceptance Criteria
- [ ] Available jobs appear in provider feed within 5 seconds of customer creating a job (via SignalR)
- [ ] Job detail screen shows countdown timer counting down from 2:00 in real time
- [ ] Timer turns red and pulses when under 30 seconds
- [ ] Accepting a job transitions it from `Pending → Accepted` in the DB
- [ ] Customer receives `JobAccepted` SignalR event within 2 seconds of provider accepting
- [ ] Rejecting a job keeps it `Pending` and logs to `job_rejections`
- [ ] If no provider accepts within 2 minutes, background service marks job `Expired`
- [ ] Customer receives `JobExpired` SignalR event when job expires
- [ ] Race condition handled — second provider to accept gets a clear error
- [ ] Unverified provider cannot see or accept jobs
- [ ] Provider location is updated via POST /api/providers/location and used in distance calculation
- [ ] All provider app screens render correctly in RTL Arabic layout
