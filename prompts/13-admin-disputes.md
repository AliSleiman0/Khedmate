# Feature: Admin Disputes (#13)
**Phase 3 — Operations**

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module: `bookings.*`, `payments.*`)
- Real-time: SignalR
- Frontend: React + TypeScript + Tailwind CSS (`web-admin/`)
- Mobile: Flutter + Riverpod + Dio (`mobile-customer/`)
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`
- Prerequisites: Features #01–#12 must be implemented. The `payments.transactions` table exists with `Held`, `Disputed`, and `Refunded` statuses. The `Transaction` domain entity already has `MarkDisputed()` and `MarkRefunded()` methods. The `IPaymentProvider` interface lives in `Modules/Payments/Khudmati.Modules.Payments/Application/IPaymentProvider.cs`.

## Goal
Allow customers to raise a dispute within the 24-hour payment hold window, and give the admin team a real, data-driven mediation workspace to review evidence, approve refunds, or close disputes — replacing the current mock-data `Disputes.tsx` page.

## Platforms Affected
- [x] Customer Mobile App (`mobile-customer/`)
- [x] Web Admin Panel (`web-admin/`)
- [x] Backend (`backend/`) — new table, new commands/queries, Stripe refund integration

---

## User Stories
- As a **customer**, I want to raise a dispute on a recently completed job (within 24 hours) so that I can request a refund if I'm unhappy with the service.
- As a **customer**, I want to see my open dispute status on the job detail screen so I know my case is being reviewed.
- As an **admin**, I want to see all open disputes in a real list so I can prioritise and investigate each case.
- As an **admin**, I want to drill into a dispute and see the customer's complaint, the job photos, and the full job timeline so I can make a fair decision.
- As an **admin**, I want to approve a refund (trigger a Stripe refund to the customer) or reject the dispute (release payment to the provider) from the same screen.

---

## Screens / Components to Build

### Customer App — Screen: Raise Dispute Flow

**Entry point:** Job Detail screen (existing). Add a "Raise Dispute" button that is only visible when:
- `job.status == 'Paid'` AND
- `transaction.status == 'Held'` (i.e. the 24h window is still open — confirmed via API)

**Screen: RaiseDisputeScreen** (new)
- Route: pushed from Job Detail
- Header: "رفع شكوى" / "Raise a Dispute"
- Body:
  - Job reference number shown as read-only chip at the top
  - Short explainer text: "If you're unsatisfied with the service, describe your issue below. Our team will review your case within 24 hours."
  - `TextFormField` — complaint text area (Arabic/English), required, min 20 characters, max 1000 characters
  - Counter showing characters remaining
  - "Submit Dispute" primary button (brand blue `#1B4F72`)
- On submit: call `POST /api/bookings/jobs/{jobId}/dispute`, show success bottom sheet with message "تم رفع شكواك بنجاح. سيتواصل معك فريق الدعم خلال 24 ساعة." then pop back to Job Detail
- On Job Detail after dispute is submitted: hide "Raise Dispute" button; show a read-only status chip "Dispute Open" in amber `#F39C12`

### Admin Panel — Screen: Disputes List + Detail (replace `web-admin/src/pages/Disputes/Disputes.tsx`)

**Layout:** Two-panel split (keep existing split-panel structure — the mock already has the right shell):
- **Left panel (dispute list, ~320px wide)**
- **Right panel (dispute detail)**

**Left panel enhancements:**
- Replace mock data with real API calls to `GET /api/admin/disputes`
- **Stats bar** at the very top: 3 count chips — Open (red), Resolved (green), Rejected (grey)
- **Filter toolbar**: status dropdown (All | Open | Resolved | Rejected) + text search (debounced 300ms) matching customer name, provider name, job ref#
- Each list item shows: Dispute ID, Job Ref#, Customer name, Amount, created date, status badge
- Loading skeleton; empty state "No disputes match your filters"

**Right panel enhancements:**
- **Header**: Dispute ID + Status badge + created date
- **Job Summary section**: Job Ref#, Customer name+ID, Provider name+ID, Category, Amount (from transaction), Job created at, Job completed at
- **Complaint section**: Full complaint text in a readable card (support Arabic RTL text direction automatically)
- **Evidence section**: Grid of job photos from `bookings.job_photos` (same photos shown in job detail — provider uploaded before marking complete)
- **Job Timeline section**: Status history from `bookings.job_status_history`
- **Admin Note field**: `<textarea>` — required before resolving; admin must type a note to explain their decision (min 10 chars)
- **Action buttons** (only visible when status is `Open`):
  - "✅ Approve Refund" — green button — calls `POST /api/admin/disputes/{disputeId}/resolve` with `{ action: "approve_refund", adminNote }`
  - "❌ Reject Dispute" — red button — calls `POST /api/admin/disputes/{disputeId}/resolve` with `{ action: "reject", adminNote }`
  - Both buttons show a confirmation dialog before firing
- **Resolved / Rejected state**: show admin note in a coloured card; no action buttons

---

## API Endpoints Required

### POST /api/bookings/jobs/{jobId}/dispute
- Auth: Customer JWT (`[Authorize(Policy = "CustomerOnly")]`)
- Controller: `backend/src/Khudmati.API/Controllers/BookingsController.cs` (existing — add new action)
- Request body:
```json
{ "complaint": "string (min 20, max 1000 chars)" }
```
- Business rules:
  1. Load job by ID; verify `job.CustomerId == authenticatedCustomerId`
  2. Verify `job.Status == Paid` — else return `DISPUTE_NOT_ALLOWED_IN_CURRENT_STATUS` (422)
  3. Load transaction via `IPaymentsRepository.GetByJobIdAsync(jobId)` — verify `transaction.Status == "Held"` — else return `DISPUTE_WINDOW_CLOSED` (422) (24h window already elapsed and payment was auto-released)
  4. Verify no existing open dispute for this job (query `bookings.disputes` where `JobId == jobId && Status == "Open"`) — else return `DISPUTE_ALREADY_EXISTS` (422)
  5. Call `transaction.MarkDisputed()` — this prevents `PaymentReleaseService` from auto-releasing (it only queries `Status == "Held"`)
  6. Create and persist a new `Dispute` entity in `bookings.disputes`
  7. Dispatch `DisputeOpenedEvent` domain event → event handler fires SignalR `DisputeOpened` to `provider-{providerId}` group (provider is notified their payment is under dispute)
- Response:
```json
{ "success": true, "data": { "disputeId": "uuid" } }
```
- Errors: `DISPUTE_NOT_ALLOWED_IN_CURRENT_STATUS` (422), `DISPUTE_WINDOW_CLOSED` (422), `DISPUTE_ALREADY_EXISTS` (422), `JOB_NOT_FOUND` (404)

### GET /api/admin/disputes
- Auth: Admin JWT (`[Authorize(Policy = "AdminOnly")]`)
- Controller: create `backend/src/Khudmati.API/Controllers/AdminDisputesController.cs`
- Query params:
  - `status` (string, optional) — "Open" | "Resolved" | "Rejected"
  - `search` (string, optional) — matches customer name, provider name, job ref#
  - `page` (int, default 1)
  - `pageSize` (int, default 20, max 50)
- Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "disputeId": "uuid",
        "jobId": "uuid",
        "referenceNumber": "KH-20260404-0001",
        "customerId": "uuid",
        "customerName": "string",
        "providerId": "uuid",
        "providerName": "string",
        "amount": "decimal",
        "status": "Open",
        "createdAt": "ISO8601"
      }
    ],
    "totalCount": 0,
    "page": 1,
    "pageSize": 20,
    "openCount": 0,
    "resolvedCount": 0,
    "rejectedCount": 0
  }
}
```
- Business rules: JOIN `bookings.disputes` → `bookings.jobs` → `customers.accounts` + `providers.accounts` + `payments.transactions`. Include `openCount`, `resolvedCount`, `rejectedCount` as aggregate counts across ALL disputes (not just the current page) for the stats bar. Order by `createdAt DESC`.

### GET /api/admin/disputes/{disputeId}
- Auth: Admin JWT
- Response:
```json
{
  "success": true,
  "data": {
    "disputeId": "uuid",
    "jobId": "uuid",
    "referenceNumber": "string",
    "customerId": "uuid",
    "customerName": "string",
    "providerId": "uuid",
    "providerName": "string",
    "categoryId": "string",
    "address": "string",
    "amount": "decimal",
    "status": "Open",
    "complaint": "string",
    "adminNote": "string | null",
    "resolvedAt": "ISO8601 | null",
    "resolvedByAdminId": "uuid | null",
    "createdAt": "ISO8601",
    "jobCreatedAt": "ISO8601",
    "jobCompletedAt": "ISO8601 | null",
    "photos": ["url1", "url2"],
    "statusHistory": [
      { "previousStatus": "string", "newStatus": "string", "changedAt": "ISO8601", "changedBy": "string" }
    ]
  }
}
```
- Error: `DISPUTE_NOT_FOUND` → 404

### POST /api/admin/disputes/{disputeId}/resolve
- Auth: Admin JWT
- Request body:
```json
{
  "action": "approve_refund" | "reject",
  "adminNote": "string (min 10, max 500 chars)"
}
```
- Business rules:
  - Load dispute; verify `Status == "Open"` — else return `DISPUTE_ALREADY_RESOLVED` (422)
  - **If `action == "approve_refund"`:**
    1. Load transaction via `IPaymentsRepository.GetByJobIdAsync(disputeId's jobId)`
    2. Call `IPaymentProvider.RefundAsync(transaction.StripePaymentIntentId, transaction.GrossAmount, transaction.Currency)` — this issues a full Stripe refund to the customer's card
    3. Call `transaction.MarkRefunded()`
    4. Update dispute: `Status = "Resolved"`, `AdminNote = adminNote`, `ResolvedAt = UtcNow`, `ResolvedByAdminId = adminId`
    5. Notify customer via SignalR: `DisputeResolved` on `customer-{customerId}` group with `{ disputeId, action: "refunded", amount }`
    6. Notify provider via SignalR: `DisputeResolved` on `provider-{providerId}` group with `{ disputeId, action: "refunded" }`
  - **If `action == "reject"`:**
    1. Load transaction
    2. Load provider's Stripe account via `IPaymentsRepository.GetProviderStripeAccountAsync(providerId)`
    3. Call `IPaymentProvider.TransferToProviderAsync(stripeAccountId, transaction.NetAmount, transaction.Currency)` — release net amount to provider
    4. Call `transaction.MarkReleased(stripeTransferId)`
    5. Update dispute: `Status = "Rejected"`, `AdminNote = adminNote`, `ResolvedAt = UtcNow`, `ResolvedByAdminId = adminId`
    6. Notify customer: `DisputeResolved` on `customer-{customerId}` with `{ disputeId, action: "rejected" }`
    7. Notify provider: `DisputeResolved` on `provider-{providerId}` with `{ disputeId, action: "payment_released" }`
- Response: `{ "success": true, "data": { "disputeId": "uuid", "newStatus": "Resolved" | "Rejected" } }`
- Errors: `DISPUTE_NOT_FOUND` (404), `DISPUTE_ALREADY_RESOLVED` (422), `STRIPE_REFUND_FAILED` (502)

---

## Data Model / DB Changes

### New table: `bookings.disputes`
```sql
CREATE TABLE bookings.disputes (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id          UUID        NOT NULL REFERENCES bookings.jobs(id),
    customer_id     UUID        NOT NULL,
    provider_id     UUID        NOT NULL,
    complaint       TEXT        NOT NULL,
    admin_note      TEXT        NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'Open',  -- Open | Resolved | Rejected
    resolved_at     TIMESTAMPTZ NULL,
    resolved_by_admin_id UUID   NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_disputes_job_id     ON bookings.disputes(job_id);
CREATE INDEX ix_disputes_status     ON bookings.disputes(status);
```

### New domain entity: `Dispute`
File: `Modules/Bookings/Khudmati.Modules.Bookings/Domain/Entities/Dispute.cs`
```csharp
public class Dispute : AuditableEntity
{
    public Guid JobId { get; private set; }
    public Guid CustomerId { get; private set; }
    public Guid ProviderId { get; private set; }
    public string Complaint { get; private set; } = string.Empty;
    public string? AdminNote { get; private set; }
    public string Status { get; private set; } = "Open";  // Open | Resolved | Rejected
    public DateTime? ResolvedAt { get; private set; }
    public Guid? ResolvedByAdminId { get; private set; }

    private Dispute() { }

    public static Dispute Open(Guid jobId, Guid customerId, Guid providerId, string complaint) => new()
    {
        JobId = jobId, CustomerId = customerId, ProviderId = providerId, Complaint = complaint
    };

    public void Resolve(string status, string adminNote, Guid adminId)
    {
        Status = status;
        AdminNote = adminNote;
        ResolvedAt = DateTime.UtcNow;
        ResolvedByAdminId = adminId;
        SetUpdated();
    }
}
```

### EF configuration
Add to `Program.cs` inside `AppDbContext.AdditionalModelConfiguration(modelBuilder)` (following the project convention — never in `Khudmati.Shared`):
```csharp
modelBuilder.Entity<Dispute>(b =>
{
    b.ToTable("disputes", "bookings");
    b.HasKey(d => d.Id);
    b.Property(d => d.Complaint).HasMaxLength(1000).IsRequired();
    b.Property(d => d.AdminNote).HasMaxLength(500);
    b.Property(d => d.Status).HasMaxLength(20).IsRequired();
    b.HasIndex(d => d.JobId);
    b.HasIndex(d => d.Status);
});
```

### Add EF migration
Run: `dotnet ef migrations add AddDisputesTable --project src/Khudmati.API` to generate the migration file.

### `IPaymentProvider` — new method
Add `RefundAsync` to `IPaymentProvider.cs`:
```csharp
Task<bool> RefundAsync(string paymentIntentId, decimal amount, string currency, CancellationToken ct = default);
```
Implement in `StripePaymentProvider.cs` using `Stripe.RefundService` with `{ PaymentIntentId = paymentIntentId, Amount = (long)(amount * 100) }`.

---

## Backend Implementation Notes

### New Command: `OpenDisputeCommand`
File: `Modules/Bookings/Application/Commands/OpenDisputeCommand.cs`
- Parameters: `JobId`, `CustomerId`, `Complaint`
- Handler: follows the 7-step business rule logic from POST /api/bookings/jobs/{jobId}/dispute above
- Inject: `IBookingsRepository`, `IPaymentsRepository`, `IPublisher` (MediatR)
- Dispatch `DisputeOpenedEvent(JobId, CustomerId, ProviderId, DisputeId)` after persisting

### New Query: `GetAdminDisputesQuery`
File: `Modules/Bookings/Application/Queries/GetAdminDisputesQuery.cs`
- Parameters: `Status?`, `Search?`, `Page`, `PageSize`
- JOINs: `bookings.disputes` → `bookings.jobs` → `customers.accounts` + `providers.accounts` + `payments.transactions`
- Aggregate counts: run a secondary `GroupBy` or COUNT queries for stats bar totals

### New Query: `GetAdminDisputeDetailQuery`
File: `Modules/Bookings/Application/Queries/GetAdminDisputeDetailQuery.cs`
- Parameters: `DisputeId`
- Loads `Dispute`, joined to `Job`, `JobStatusHistory`, `JobPhotos`, `customers.accounts`, `providers.accounts`, `payments.transactions`

### New Command: `ResolveDisputeCommand`
File: `Modules/Payments/Application/Commands/ResolveDisputeCommand.cs`
- Parameters: `DisputeId`, `Action` ("approve_refund" | "reject"), `AdminNote`, `AdminId`
- Inject: `IBookingsRepository` (to load/save Dispute), `IPaymentsRepository`, `IPaymentProvider`, `IPublisher`
- Follows the two-branch business rule logic from POST /api/admin/disputes/{disputeId}/resolve above
- Dispatch `DisputeResolvedEvent(DisputeId, JobId, CustomerId, ProviderId, Action)` after persisting

### Repository additions

**`IBookingsRepository` / `BookingsRepository.cs`** — add:
```csharp
Task<Dispute?> GetDisputeByJobIdAsync(Guid jobId, CancellationToken ct = default);
Task AddDisputeAsync(Dispute dispute, CancellationToken ct = default);
Task<Dispute?> GetDisputeByIdAsync(Guid disputeId, CancellationToken ct = default);
Task<(IReadOnlyList<AdminDisputeSummary> Items, int Total, int OpenCount, int ResolvedCount, int RejectedCount)>
    GetAdminDisputesAsync(string? status, string? search, int page, int pageSize, CancellationToken ct = default);
```

### New Event Handlers (in `Khudmati.API/EventHandlers/`)

**`DisputeOpenedEventHandler.cs`**
- Triggered by `DisputeOpenedEvent`
- Sends SignalR `DisputeOpened` to `provider-{providerId}` group:
```json
{ "disputeId": "uuid", "jobId": "uuid", "message": "A customer has raised a dispute on your job." }
```

**`DisputeResolvedEventHandler.cs`**
- Triggered by `DisputeResolvedEvent`
- Sends SignalR `DisputeResolved` to `customer-{customerId}`:
  - approve_refund: `{ "disputeId": "uuid", "outcome": "refunded", "message": "Your dispute has been approved. A refund has been issued to your card." }`
  - reject: `{ "disputeId": "uuid", "outcome": "rejected", "message": "Your dispute was reviewed and rejected. No refund will be issued." }`
- Sends SignalR `DisputeResolved` to `provider-{providerId}`:
  - approve_refund: `{ "disputeId": "uuid", "outcome": "refunded", "message": "The customer's dispute was approved. Your payment will not be released." }`
  - reject: `{ "disputeId": "uuid", "outcome": "payment_released", "message": "The dispute was rejected. Your payment has been released." }`

---

## Frontend Implementation Notes

### Admin Panel

**API layer** — create `web-admin/src/api/disputes.ts`:
```typescript
export interface AdminDisputeSummary {
  disputeId: string; jobId: string; referenceNumber: string;
  customerId: string; customerName: string;
  providerId: string; providerName: string;
  amount: number; status: 'Open' | 'Resolved' | 'Rejected'; createdAt: string;
}
export interface AdminDisputeDetail extends AdminDisputeSummary {
  categoryId: string; address: string; complaint: string;
  adminNote: string | null; resolvedAt: string | null; resolvedByAdminId: string | null;
  jobCreatedAt: string; jobCompletedAt: string | null;
  photos: string[];
  statusHistory: { previousStatus: string; newStatus: string; changedAt: string; changedBy: string }[];
}
export interface AdminDisputesResponse {
  items: AdminDisputeSummary[]; totalCount: number; page: number; pageSize: number;
  openCount: number; resolvedCount: number; rejectedCount: number;
}
export async function fetchAdminDisputes(params: {...}): Promise<AdminDisputesResponse>
export async function fetchAdminDisputeDetail(disputeId: string): Promise<AdminDisputeDetail>
export async function resolveDispute(disputeId: string, action: 'approve_refund' | 'reject', adminNote: string): Promise<void>
```

**Component files to modify/create:**
| File | Action |
|---|---|
| `web-admin/src/pages/Disputes/Disputes.tsx` | Replace all mock data with real API; add stats bar, filter toolbar, loading states |
| `web-admin/src/api/disputes.ts` | New — typed API functions |

**State**: Use local `useState` + `useEffect` in `Disputes.tsx`. No Zustand store needed — page-level state only. Debounce search with 300ms `setTimeout`.

**Confirmation dialog pattern**: Use a simple inline state (`confirmAction: 'approve_refund' | 'reject' | null`) to show a modal overlay before calling the API — match the confirmation dialog pattern used in `JobDetailDrawer.tsx` from feature #12.

### Customer Mobile App

**New screen** — `mobile-customer/lib/features/bookings/presentation/pages/raise_dispute_screen.dart`
- StatefulWidget with a `_formKey`, `TextEditingController` for complaint
- AppBar: "رفع شكوى"
- Character count listener on controller
- Calls `POST /api/bookings/jobs/{jobId}/dispute` via `BookingRepository.raiseDisputeAsync(jobId, complaint)`
- Shows SnackBar on success then pops; shows error SnackBar with mapped error codes on failure

**Update** — `mobile-customer/lib/features/bookings/presentation/pages/job_detail_screen.dart` (existing):
- Add a `ref.watch(jobDetailProvider(jobId))` to get `transaction.status == 'Held'` — if so, show an amber-outlined "Raise Dispute" button at the bottom
- After dispute is successfully raised, invalidate the provider to refresh the job detail (the API now returns `hasOpenDispute: true`)

**New repository method** — `mobile-customer/lib/features/bookings/data/repositories/booking_repository.dart`:
```dart
Future<String> raiseDispute(String jobId, String complaint) async {
  final response = await _dio.post(
    '/bookings/jobs/$jobId/dispute',
    data: {'complaint': complaint},
  );
  return response.data['data']['disputeId'] as String;
}
```

**Update `GET /api/bookings/jobs/{jobId}` response** (or the existing job detail endpoint):
- Add `hasOpenDispute: bool` field → set to `true` if a row in `bookings.disputes` with `Status == "Open"` exists for this job
- This field drives whether the customer sees the "Raise Dispute" button or the "Dispute Open" status chip

---

## Real-time / Notifications

| Event | Fired when | Group | Payload |
|---|---|---|---|
| `DisputeOpened` | Customer raises dispute | `provider-{providerId}` | `{ disputeId, jobId, message }` |
| `DisputeResolved` | Admin approves refund | `customer-{customerId}` | `{ disputeId, outcome: "refunded", message }` |
| `DisputeResolved` | Admin approves refund | `provider-{providerId}` | `{ disputeId, outcome: "refunded", message }` |
| `DisputeResolved` | Admin rejects dispute | `customer-{customerId}` | `{ disputeId, outcome: "rejected", message }` |
| `DisputeResolved` | Admin rejects dispute | `provider-{providerId}` | `{ disputeId, outcome: "payment_released", message }` |

---

## Edge Cases & Validation

- **Dispute window already closed**: transaction status is `Released` (auto-released by `PaymentReleaseService`) → `DISPUTE_WINDOW_CLOSED` (422). The "Raise Dispute" button should not even be shown on the customer side in this state — `hasOpenDispute: false` and `transaction.status != 'Held'` both gate the button.
- **Duplicate dispute**: second submit while first is still `Open` → `DISPUTE_ALREADY_EXISTS` (422).
- **Stripe refund fails**: `IPaymentProvider.RefundAsync` throws → return `STRIPE_REFUND_FAILED` (502). Do NOT mark the dispute resolved — leave it `Open` so admin can retry.
- **Provider has no Stripe account** on reject path: `GetProviderStripeAccountAsync` returns null → return `PROVIDER_STRIPE_ACCOUNT_NOT_FOUND` (422). Admin should flag this case manually.
- **Admin resolves a non-Open dispute**: return `DISPUTE_ALREADY_RESOLVED` (422) — the frontend should already hide the action buttons but the backend must validate regardless.
- **Admin note required**: enforce min 10 chars on both frontend (disable button) and backend (validation guard).
- **Empty dispute list**: show illustration + "لا توجد نزاعات مفتوحة" / "No disputes found" empty state in the left panel.
- **Job photos**: if no photos were uploaded (edge case), show "No evidence photos uploaded" in the evidence section — not an error.
- **RTL complaint text**: the complaint textarea in the admin detail panel must detect Arabic content and apply `dir="rtl"` / `text-align: right` automatically.

---

## Out of Scope (do not implement)
- Partial refunds (always full `GrossAmount` refund in V1)
- Customer appeal after dispute is rejected
- Admin-to-customer chat within the dispute
- Automated dispute resolution or AI triage
- Super admin dispute oversight (feature #15)
- Email notifications (push/SignalR only in V1)
- Dispute SLA timers or escalation alerts

---

## Acceptance Criteria

**Backend:**
- [ ] `POST /api/bookings/jobs/{jobId}/dispute` creates a `bookings.disputes` row and calls `transaction.MarkDisputed()` — preventing auto-release
- [ ] `POST /api/bookings/jobs/{jobId}/dispute` returns `DISPUTE_WINDOW_CLOSED` when transaction is already `Released`
- [ ] `POST /api/bookings/jobs/{jobId}/dispute` returns `DISPUTE_ALREADY_EXISTS` on a second attempt
- [ ] `GET /api/admin/disputes` returns paginated real disputes with `openCount`, `resolvedCount`, `rejectedCount` aggregates
- [ ] `GET /api/admin/disputes/{disputeId}` returns full detail including complaint, photos, and status history
- [ ] `POST /api/admin/disputes/{disputeId}/resolve` with `approve_refund` triggers Stripe refund, marks transaction `Refunded`, marks dispute `Resolved`
- [ ] `POST /api/admin/disputes/{disputeId}/resolve` with `reject` triggers Stripe transfer to provider, marks transaction `Released`, marks dispute `Rejected`
- [ ] `STRIPE_REFUND_FAILED` (502) is returned without mutating dispute state when Stripe call fails
- [ ] `RefundAsync` is added to `IPaymentProvider` and implemented in `StripePaymentProvider`
- [ ] EF migration for `bookings.disputes` table is generated and applies cleanly
- [ ] `Dispute` entity is configured in `Program.cs` (not in `Khudmati.Shared`)

**Admin Panel:**
- [ ] Disputes list page shows real data (no mocks), status filter and search work
- [ ] Stats bar shows correct Open / Resolved / Rejected counts
- [ ] Dispute detail panel shows complaint text, evidence photos, job timeline, and admin note field
- [ ] "Approve Refund" and "Reject Dispute" buttons are visible only for Open disputes; require confirmation
- [ ] Admin note field must have at least 10 characters before the action buttons are enabled
- [ ] Resolved/Rejected disputes show the admin note in a coloured card; action buttons are hidden
- [ ] Arabic complaint text renders RTL correctly
- [ ] No TypeScript errors; no `any` types in the API layer

**Customer App:**
- [ ] "Raise Dispute" button appears on the Job Detail screen only when `job.status == Paid` and `transaction.status == Held`
- [ ] RaiseDisputeScreen validates complaint is at least 20 characters before enabling submit
- [ ] Successful dispute submission shows Arabic success bottom sheet and pops back to Job Detail
- [ ] Job Detail shows "Dispute Open" amber chip after a dispute is raised (no "Raise Dispute" button)
- [ ] Error codes `DISPUTE_WINDOW_CLOSED` and `DISPUTE_ALREADY_EXISTS` show user-friendly Arabic error messages
- [ ] RTL layout correct on all new screens; Cairo font used for Arabic text
