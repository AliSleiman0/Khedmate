# Feature: Maintenance Reminders (AI Scheduling)

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer), React + TypeScript (web-admin)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#06 and #10 (push notifications) must be implemented. Reminders are triggered when a job reaches `Paid` status.

## Goal
After a customer's job is completed and paid for, the platform automatically schedules a follow-up reminder based on the service category (e.g., "AC cleaning every 3 months"). The customer receives a push notification and an in-app reminder card at the scheduled time. Tapping the reminder pre-fills the booking form. "AI scheduling" in V1 is rule-based (admin-configured intervals per category) with an architecture that supports replacing the rule engine with an LLM inference call later using a feature flag.

## Platforms Affected
- [x] Customer Mobile App (Flutter)
- [x] Backend (.NET 8)
- [x] Web Admin Panel (React + TypeScript) — reminder rule configuration
- [ ] Provider Mobile App — no changes
- [ ] Web Landing Page — no changes
- [ ] Web Super Admin Panel — no changes

---

## User Stories
- As a **customer**, I want to be reminded when it's time to rebook a service so I don't forget routine maintenance.
- As a **customer**, I want to tap a reminder and go straight to the booking form, pre-filled with the same service.
- As a **customer**, I want to snooze or dismiss reminders I don't need.
- As an **admin**, I want to configure the reminder interval for each service category so the platform can follow industry best practices.

---

## How "AI Scheduling" Works in V1

V1 uses rule-based scheduling with a clear seam for future AI:

```
IRemindersScheduler (interface)
  └── RuleBasedRemindersScheduler (V1 implementation)
        Reads: public.reminder_rules (admin-configured interval per category)
        Output: scheduled_for = last_job_completed_at + interval_days
  └── AiRemindersScheduler (V2, behind feature flag)
        Calls OpenAI / Azure OpenAI with context: category, frequency of past bookings, season
        Output: AI-suggested date
```

Feature flag: `Features:AiScheduling` in `appsettings.json` (boolean). When `false`, use `RuleBasedRemindersScheduler`. When `true`, use `AiRemindersScheduler`. Both are registered in DI; the flag controls which is injected. This means the interface, DI registration, and flag check should be implemented now, but only `RuleBasedRemindersScheduler` needs a working body.

---

## Database Changes

### New table: `public.reminder_rules`
Admin-managed. One row per category.
```sql
CREATE TABLE public.reminder_rules (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id          UUID NOT NULL,          -- FK to your categories table
    category_name_ar     VARCHAR(100) NOT NULL,  -- denormalised for display
    interval_days        INT NOT NULL,            -- e.g. 90 for AC (every 3 months)
    is_active            BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Seed example rows:
| Category (AR) | Interval |
|---|---|
| تكييف وتبريد (AC) | 90 days |
| تنظيف عام (General Cleaning) | 30 days |
| صيانة كهربائية (Electrical) | 365 days |
| سباكة (Plumbing) | 180 days |
| نجارة (Carpentry) | 365 days |

### New table: `public.scheduled_reminders`
```sql
CREATE TABLE public.scheduled_reminders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    job_id          UUID NOT NULL REFERENCES bookings.jobs(id),
    category_id     UUID NOT NULL,
    category_name_ar VARCHAR(100) NOT NULL,
    scheduled_for   TIMESTAMPTZ NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    -- Scheduled | Sent | Dismissed | Snoozed | Booked
    snoozed_until   TIMESTAMPTZ,
    sent_at         TIMESTAMPTZ,
    dismissed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_scheduled_reminders_due
    ON public.scheduled_reminders(scheduled_for)
    WHERE status = 'Scheduled';
CREATE INDEX idx_scheduled_reminders_customer
    ON public.scheduled_reminders(customer_id);
```

### EF Configuration
Add entity configurations in `Program.cs` via `AppDbContext.AdditionalModelConfiguration`.

---

## Backend Changes

### 1. Schedule reminder on job paid — event handler

**File:** `Khudmati.API/EventHandlers/MaintenanceReminderHandler.cs`

Subscribe to `PaymentReleasedEvent` (or `JobStatusChangedEvent` for `Paid`). When fired:
1. Load the job's `categoryId`.
2. Look up `public.reminder_rules` for that `category_id` where `is_active = true`.
3. If no rule exists for this category, do nothing (silently skip — not all categories have reminders).
4. Call `IRemindersScheduler.ComputeScheduledDate(categoryId, job.CompletedAt)`.
5. Insert a `public.scheduled_reminders` row with `status = Scheduled`.

### 2. Background worker — send due reminders

**File:** `Khudmati.API/Infrastructure/BackgroundServices/ReminderDispatchWorker.cs`

Runs every hour via `BackgroundService` + `PeriodicTimer`.

Logic per cycle:
1. Query `scheduled_reminders` where `scheduled_for <= now() AND status = 'Scheduled'`.
   Also include snoozed reminders: `status = 'Snoozed' AND snoozed_until <= now()`.
2. For each reminder:
   a. Send push notification (via existing `SendPushNotificationCommand`):
      - Title: "حان وقت الصيانة! 🔧"
      - Body: "حان موعد {categoryName} — احجز الآن بنقرة واحدة"
      - Data payload: `{ "type": "MAINTENANCE_REMINDER", "reminderId": "...", "categoryId": "..." }`
   b. Check if customer has unread in-app notifications — update badge count.
   c. Set `status = Sent`, `sent_at = now()`.
3. Process in batches of 100 to avoid memory spikes.

### 3. Reminder actions — new commands

**File:** `Modules/Customers/Application/Commands/UpdateReminderStatusCommand.cs`
```csharp
public record UpdateReminderStatusCommand(
    Guid CustomerId,
    Guid ReminderId,
    ReminderAction Action,      // Dismiss | Snooze | MarkBooked
    int? SnoozeDays             // required when Action = Snooze
) : IRequest<Result>;
```

**Handler logic:**
- `Dismiss`: set `status = Dismissed`, `dismissed_at = now()`
- `Snooze`: set `status = Snoozed`, `snoozed_until = now() + SnoozeDays days` (max 30 days)
- `MarkBooked`: set `status = Booked` (called when customer creates a booking from the reminder deep link)

### 4. IRemindersScheduler interface + implementations

**File:** `Modules/Customers/Application/Services/IRemindersScheduler.cs`
```csharp
public interface IRemindersScheduler
{
    Task<DateTime> ComputeScheduledDateAsync(Guid categoryId, DateTime lastJobCompletedAt);
}
```

**File:** `Modules/Customers/Infrastructure/RuleBasedRemindersScheduler.cs`
```csharp
public class RuleBasedRemindersScheduler : IRemindersScheduler
{
    public async Task<DateTime> ComputeScheduledDateAsync(Guid categoryId, DateTime lastJobCompletedAt)
    {
        var rule = await _context.Set<ReminderRule>()
            .FirstOrDefaultAsync(r => r.CategoryId == categoryId && r.IsActive);
        if (rule == null) throw new InvalidOperationException("No rule for category");
        return lastJobCompletedAt.AddDays(rule.IntervalDays);
    }
}
```

**File:** `Modules/Customers/Infrastructure/AiRemindersScheduler.cs`
- Stub only — throws `NotImplementedException` with a comment: `// TODO: Call OpenAI API with booking history context`
- Registered in DI but never called in V1

DI registration in `Program.cs`:
```csharp
var useAi = builder.Configuration.GetValue<bool>("Features:AiScheduling");
if (useAi)
    builder.Services.AddScoped<IRemindersScheduler, AiRemindersScheduler>();
else
    builder.Services.AddScoped<IRemindersScheduler, RuleBasedRemindersScheduler>();
```

### 5. Admin rule management — new endpoints

`GET /api/admin/reminder-rules` — list all rules
`PUT /api/admin/reminder-rules/{id}` — update interval or toggle active

### 6. Customer reminders query

**File:** `Modules/Customers/Application/Queries/GetMyRemindersQuery.cs`

Returns reminders for the current customer with `status IN (Scheduled, Sent, Snoozed)`, ordered by `scheduled_for ASC`. Excludes dismissed and booked.

---

## API Endpoints

### GET /api/customers/me/reminders
Returns upcoming reminders for the customer.
- Auth: Customer JWT
- Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "categoryId": "...",
      "categoryNameAr": "تكييف وتبريد",
      "scheduledFor": "2026-07-04T09:00:00Z",
      "status": "Scheduled",
      "lastJobId": "..."
    }
  ]
}
```

### PATCH /api/customers/me/reminders/{id}
Dismiss, snooze, or mark booked.
- Auth: Customer JWT
- Request: `{ "action": "Snooze", "snoozeDays": 7 }` or `{ "action": "Dismiss" }`
- Response: `{ "success": true }`
- Error codes: `REMINDER_NOT_FOUND`, `REMINDER_ALREADY_DISMISSED`, `SNOOZE_DAYS_EXCEEDED`

### GET /api/admin/reminder-rules
- Auth: Admin JWT
- Response: list of all reminder rules with category info

### PUT /api/admin/reminder-rules/{id}
- Auth: Admin JWT
- Request: `{ "intervalDays": 60, "isActive": true }`
- Response: updated rule

---

## Customer App Changes

### New Screen: Reminders Screen (`lib/features/reminders/presentation/reminders_screen.dart`)

**Layout:**
- AppBar: "تذكيرات الصيانة" (Maintenance Reminders)
- Empty state (if no reminders): icon + "لا توجد تذكيرات حالياً" (No reminders yet) — friendly illustration
- Reminder card for each upcoming reminder:
  - Category icon + name in Arabic
  - Due date formatted: "بعد ٤٥ يوماً — ٤ يوليو ٢٠٢٦"
  - If overdue (scheduled_for < now): amber badge "متأخر" (Overdue)
  - "احجز الآن" (Book Now) button — primary, brand blue → navigates to booking flow pre-filled with categoryId
  - Three-dot menu: "تأجيل أسبوع" (Snooze 1 week), "تأجيل شهر" (Snooze 1 month), "تجاهل" (Dismiss)

### Update: Home Screen / Notification Bell
- Show a badge on the notification bell if there are `Sent` or overdue reminders
- In the notifications list, maintenance reminders appear as a distinct card type with a wrench icon

### Deep Link Handling
Push notification payload includes `{ "type": "MAINTENANCE_REMINDER", "categoryId": "..." }`. Tapping the notification:
1. Opens the app
2. Navigates to the booking flow with `categoryId` pre-selected
3. PATCH reminder status to `Booked` after booking is confirmed

Register deep link handler in `lib/core/services/notification_handler.dart` (or equivalent).

### State Management

New Riverpod provider: `lib/features/reminders/presentation/reminders_provider.dart`
```dart
@riverpod
class RemindersNotifier extends _$RemindersNotifier {
  @override
  Future<List<ReminderModel>> build() =>
      ref.read(remindersRepositoryProvider).getMyReminders();

  Future<void> snooze(String reminderId, int days) async { ... }
  Future<void> dismiss(String reminderId) async { ... }
}
```

New repository: `lib/features/reminders/data/reminders_repository.dart`

---

## Admin Panel Changes (`web-admin/`)

### New Page: Reminder Rules (`web-admin/src/pages/reminders/ReminderRulesPage.tsx`)
Route: `/reminder-rules`

- Table: Category | Reminder interval | Status (Active/Inactive) | Edit button
- Edit modal: change interval (days input) + active toggle
- Read-only stats column: "Total sent this month: 142"

---

## Edge Cases & Validation

- If no reminder rule exists for the job's category: silently skip — do not throw or log a warning
- If a customer has already been reminded about the same category within the last 14 days (duplicate job scenario), skip scheduling a new reminder
- Snooze maximum: 30 days. Attempts beyond 30 days return `SNOOZE_DAYS_EXCEEDED`
- Background worker must be idempotent: check `status = Scheduled` before sending to avoid double-sends if the worker restarts mid-cycle
- `MarkBooked` action can only be called once; subsequent calls are no-ops
- Dismiss is permanent — no undo
- If the customer deletes their account, `ON DELETE CASCADE` handles cleanup

---

## Out of Scope (do not implement)
- True AI inference (GPT/OpenAI call) — stub the interface only
- Customer-configurable custom intervals
- Email reminders
- Recurring automatic re-scheduling after each job indefinitely (V1 is one reminder per job)
- Provider-side reminders
- SMS reminders

---

## File Locations

| File | Purpose |
|---|---|
| `Khudmati.API/EventHandlers/MaintenanceReminderHandler.cs` | Schedule reminder on payment |
| `Khudmati.API/Infrastructure/BackgroundServices/ReminderDispatchWorker.cs` | Hourly send worker |
| `Modules/Customers/Application/Services/IRemindersScheduler.cs` | Scheduler interface |
| `Modules/Customers/Infrastructure/RuleBasedRemindersScheduler.cs` | Rule-based V1 impl |
| `Modules/Customers/Infrastructure/AiRemindersScheduler.cs` | AI stub (not used in V1) |
| `Modules/Customers/Application/Commands/UpdateReminderStatusCommand.cs` | Dismiss/snooze/booked |
| `Modules/Customers/Application/Queries/GetMyRemindersQuery.cs` | List reminders |
| `Khudmati.API/Controllers/CustomersController.cs` | Reminder endpoints |
| `Khudmati.API/Controllers/AdminController.cs` | Reminder rule admin endpoints |
| `lib/features/reminders/presentation/reminders_screen.dart` | Customer reminders screen |
| `lib/features/reminders/presentation/reminders_provider.dart` | Riverpod state |
| `lib/features/reminders/data/reminders_repository.dart` | API calls |
| `web-admin/src/pages/reminders/ReminderRulesPage.tsx` | Admin rule management |

---

## Acceptance Criteria
- [ ] A reminder is scheduled automatically when a job reaches `Paid` status and a reminder rule exists for the category
- [ ] No reminder is created if no rule exists for the category
- [ ] Background worker sends the push notification on or after `scheduled_for`
- [ ] Customer receives "حان وقت الصيانة" push notification with correct category name
- [ ] Tapping the notification navigates to the booking form pre-filled with the category
- [ ] Customer can snooze (≤30 days) or dismiss a reminder from the app
- [ ] Admin can view and edit reminder rules per category in the admin panel
- [ ] `AiRemindersScheduler` stub exists and is wired via feature flag — switching `Features:AiScheduling` to true compiles without errors
- [ ] All UI text is in Arabic; layout is RTL
