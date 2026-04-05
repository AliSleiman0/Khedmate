# Feature: Job Status Tracking

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer, mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01 (Auth), #02 (Customer Booking), #03 (Provider Job Acceptance) must be implemented first

## Goal
After a provider accepts a job, both sides need to track it through to completion. The provider advances the job through `EnRoute → InProgress → Completed`. The customer sees each transition in real time. This closes the operational loop — a job can now go all the way from creation to done.

## Platforms Affected
- [x] Provider Mobile App (Flutter) — provider drives status transitions
- [x] Customer Mobile App (Flutter) — customer watches status update in real time
- [x] Backend (.NET 8) — enforces state machine, fires SignalR events
- [ ] Admin Panel — feature #12
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **provider**, I want to mark myself as en route, start the job, and complete it so the customer knows what's happening at each step.
- As a **customer**, I want to see my job status update in real time so I know when the provider is coming and when the job is done.
- As the **system**, I want to enforce valid status transitions and reject invalid ones so the job lifecycle stays consistent.

---

## Job Status State Machine (full — enforce this in `Job.cs`)

```
Pending   → Accepted  (feature #03)
Accepted  → EnRoute   (provider taps "I'm on my way")
EnRoute   → InProgress (provider taps "I've arrived, starting job")
InProgress → Completed (provider taps "Job done")
Completed → Paid      (feature #05 — payments)
Pending   → Expired   (feature #03 — auto background service)
```

Any other transition must return `Result.Fail("Invalid transition")`. Never skip a step.

---

## Provider App Changes

### Update: Active Job Detail Screen (`lib/features/jobs/presentation/active_job_detail_screen.dart`)
This screen is opened when the provider taps an accepted job from their Active Jobs tab. It drives the entire status progression.

**Layout — changes per status:**

**Status: Accepted**
- Header chip: "مقبول" (Accepted) — blue
- Customer address + map pin (non-interactive)
- Big primary button: "في الطريق" (I'm on my way) — brand blue
- Tapping → calls API to transition to `EnRoute`

**Status: EnRoute**
- Header chip: "في الطريق" (En Route) — yellow
- Customer address + distance remaining (static for now — live GPS is feature #08)
- Big primary button: "وصلت، بدء العمل" (Arrived, start job) — brand blue
- Secondary info: customer name + masked phone (show last 4 digits only)
- Tapping → calls API to transition to `InProgress`

**Status: InProgress**
- Header chip: "جاري العمل" (In Progress) — amber
- Job description shown as reminder
- Big primary button: "إنهاء العمل" (Complete job) — green
- Tapping → shows confirmation bottom sheet: "هل أنت متأكد من إنهاء العمل؟" with Confirm/Cancel buttons
- On confirm → calls API to transition to `Completed`

**Status: Completed**
- Header chip: "مكتمل" (Completed) — green
- Show message: "تم إنهاء العمل بنجاح، في انتظار تأكيد الدفع" (Job completed, awaiting payment confirmation)
- No action button — waiting for payment (feature #05)

**Shared elements across all statuses:**
- Job reference number at top
- Service category + description
- Customer first name (not full name for privacy)
- Back navigation disabled while job is active — provider must complete or contact support

### Update: Active Jobs List (`lib/features/jobs/presentation/active_jobs_screen.dart`)
- Each card must show live status chip that updates via SignalR without requiring a screen refresh
- Status chip colours match the root CLAUDE.md convention

---

## Customer App Changes

### Update: Job Tracking Screen (`lib/features/booking/presentation/job_tracking_screen.dart`)
Reached from the Booking Confirmation screen after provider accepts. This is the customer's view of the ongoing job.

**Layout — changes per status:**

**Status: Accepted**
- Status banner: "تم قبول طلبك" (Your job was accepted) — blue background
- Provider name + service category
- Message: "المزود في طريقه إليك" (Provider is on their way)
- Animated pulse indicator (provider is preparing)

**Status: EnRoute**
- Status banner: "المزود في الطريق إليك" (Provider is en route) — yellow background
- Static map showing customer location pin (provider live location is feature #08)
- Provider name + estimated arrival: "يتوقع الوصول قريباً" (Expected to arrive soon) — no ETA in V1

**Status: InProgress**
- Status banner: "جاري تنفيذ الخدمة" (Service in progress) — amber background
- Job description reminder
- Contact provider button (opens phone dialer — masked number)

**Status: Completed**
- Status banner: "تم إنجاز الخدمة!" (Service completed!) — green background
- CTA: "تقييم الخدمة" (Rate the service) — amber button → navigates to Rating screen (feature #06 — stub for now, show "Coming soon" toast)
- Secondary: "العودة للرئيسية" (Back to Home)

**Real-time updates:**
- Screen listens to `JobStatusChanged` SignalR event for this `jobId`
- On event received: animate the status banner transition (simple fade/slide), update displayed status
- No manual refresh needed

### Booking History Update (`lib/features/booking/presentation/booking_history_screen.dart`)
- Each past job card must show the correct status chip
- Tapping a completed job shows a read-only detail view (reference number, category, date, address, provider name)

---

## State Management

### Provider: Active Job Notifier (`lib/features/jobs/presentation/active_job_provider.dart`)
```dart
@riverpod
class ActiveJobNotifier extends _$ActiveJobNotifier {
  @override
  Future<JobDetail> build(String jobId) async {
    _subscribeToStatusChanges(jobId);
    return ref.read(jobRepositoryProvider).getActiveJob(jobId);
  }

  void _subscribeToStatusChanges(String jobId) {
    ref.read(signalRServiceProvider).on('JobStatusChanged', (data) {
      if (data['jobId'] == jobId) {
        state = AsyncData(state.value!.copyWith(status: data['status']));
      }
    });
  }

  Future<void> advanceStatus() async {
    final job = state.value;
    if (job == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).advanceJobStatus(job.id),
    );
  }
}
```

### Customer: Job Tracking Notifier (`lib/features/booking/presentation/job_tracking_provider.dart`)
Same pattern — loads job detail, subscribes to `JobStatusChanged` for this `jobId`, updates state on event.

---

## API Endpoints

### POST /api/providers/jobs/{jobId}/advance
- Auth: Provider JWT
- Request: (empty body — next status is determined server-side from current status)
- Response:
```json
{
  "success": true,
  "data": {
    "jobId": "uuid",
    "previousStatus": "Accepted",
    "newStatus": "EnRoute",
    "updatedAt": "ISO8601"
  }
}
```
- Business rules:
  - Extract `providerId` from JWT — validate that this provider owns the job (`job.provider_id = providerId`)
  - Determine next status via state machine on `Job` entity (call `job.Advance()`)
  - If transition is invalid → `400` with `"INVALID_STATUS_TRANSITION"`
  - If provider doesn't own the job → `403`
  - On success: save, fire `JobStatusChanged` SignalR event to customer group `customer-{customerId}`
  - Log `JobStatusChangedEvent` domain event with `previousStatus`, `newStatus`, `changedAt`

### GET /api/jobs/{jobId}/status
- Auth: Customer JWT or Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "jobId": "uuid",
    "status": "EnRoute",
    "referenceNumber": "KH-20240403-0001",
    "category": "سباكة",
    "providerName": "Ahmad K.",
    "updatedAt": "ISO8601"
  }
}
```
- Business rules: Return job only if the requesting user is the customer or provider of this job. Otherwise `404`.

---

## Backend Changes

### `Job.cs` — add `Advance()` method
```csharp
public Result<JobStatus> Advance()
{
    var next = Status switch
    {
        JobStatus.Accepted    => JobStatus.EnRoute,
        JobStatus.EnRoute     => JobStatus.InProgress,
        JobStatus.InProgress  => JobStatus.Completed,
        _ => (JobStatus?)null
    };

    if (next is null)
        return Result<JobStatus>.Fail($"Cannot advance job from '{Status}' status.");

    var previous = Status;
    Status = next.Value;
    UpdatedAt = DateTime.UtcNow;
    _events.Add(new JobStatusChangedEvent(Id, previous, next.Value, DateTime.UtcNow));
    return Result<JobStatus>.Ok(next.Value);
}
```

### New files
```
Modules/Bookings/Khudmati.Modules.Bookings/
├── Application/
│   ├── Commands/
│   │   ├── AdvanceJobStatusCommand.cs
│   │   ├── AdvanceJobStatusCommandHandler.cs
│   │   └── AdvanceJobStatusCommandValidator.cs
│   └── Queries/
│       ├── GetJobStatusQuery.cs
│       └── GetJobStatusQueryHandler.cs
├── Domain/
│   └── Events/
│       └── JobStatusChangedEvent.cs
```

### SignalR — fire event from handler
In `AdvanceJobStatusCommandHandler`, after saving:
```csharp
await _hubContext.Clients
    .Group($"customer-{job.CustomerId}")
    .SendAsync("JobStatusChanged", new
    {
        JobId = job.Id,
        Status = job.Status.ToString(),
        UpdatedAt = DateTime.UtcNow
    });
```

---

## Real-time Events

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `JobStatusChanged` | Any status transition via `AdvanceJobStatusCommand` | `customer-{customerId}` | `{ jobId, status, updatedAt }` |

The provider app does not need a real-time event for this — the provider triggers the change, so their UI updates optimistically from the API response.

---

## DB Changes

```sql
-- Add status history table for full audit trail
CREATE TABLE bookings.job_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES bookings.jobs(id) ON DELETE CASCADE,
    previous_status VARCHAR(30) NOT NULL,
    new_status VARCHAR(30) NOT NULL,
    changed_by UUID NOT NULL,        -- providerId for Accepted→EnRoute→InProgress→Completed
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_job_status_history_job_id ON bookings.job_status_history(job_id);
```

No changes to `bookings.jobs` — `status` and `updated_at` columns already exist from feature #02.

---

## Edge Cases & Validation

- Provider tries to skip a step (e.g. Accepted → Completed directly) → `400 "INVALID_STATUS_TRANSITION"`
- Provider tries to advance a job that belongs to a different provider → `403`
- Customer tries to call advance endpoint → `403` (provider JWT required)
- Provider advances to Completed → customer receives `JobStatusChanged` with status `Completed` and sees the rate button
- Network drops during status update → Flutter shows error snackbar "فشل تحديث الحالة، حاول مرة أخرى" (Failed to update, try again); status is NOT updated in local state until API confirms
- Customer refreshes tracking screen manually (pull-to-refresh) → calls `GET /api/jobs/{jobId}/status` as fallback

---

## Out of Scope (do not implement)
- Live provider GPS on map — feature #08
- Payment after Completed — feature #05
- Rating after Completed — feature #06
- Push notifications for status changes — feature #10 (SignalR only for now)
- Customer cancelling an active job — V2
- Provider cancelling after accepting — V2

---

## Acceptance Criteria
- [ ] Provider can advance job through `Accepted → EnRoute → InProgress → Completed` one step at a time
- [ ] Invalid transitions (e.g. Accepted → Completed) return `400` from the API
- [ ] Customer receives `JobStatusChanged` SignalR event within 2 seconds of each transition
- [ ] Customer tracking screen updates status banner without requiring a manual refresh
- [ ] Provider cannot advance a job they don't own
- [ ] Each status transition is logged to `bookings.job_status_history`
- [ ] Confirmation bottom sheet shown before marking job Completed (provider must confirm)
- [ ] Completed status shows rate button on customer side (navigates to stub for now)
- [ ] All screens render correctly in RTL Arabic layout
