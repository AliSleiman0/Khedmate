# Feature: Admin Jobs Management (#12)
**Phase 3 — Operations**

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module: `bookings.*`)
- Real-time: SignalR
- Frontend: React + TypeScript + Tailwind CSS (`web-admin/`)
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`
- Prerequisites: Features #01–#09 must be implemented. The `bookings.jobs` and related tables exist.

## Goal
Give the admin team full operational visibility and control over every job in the platform — replacing the current mock-data `Jobs.tsx` with a real, paginated, filterable job list, a rich job detail drawer/modal, and an admin force-cancel action for stuck jobs.

## Platforms Affected
- [x] Web Admin Panel (`web-admin/`)
- [x] Backend (`backend/`) — new admin-scoped queries and one command

---

## User Stories
- As an **admin**, I want to browse all jobs across all statuses so I can monitor the platform's operational health.
- As an **admin**, I want to drill into a specific job and see its full timeline and data so I can investigate issues or disputes.
- As an **admin**, I want to force-cancel a stuck `Pending` or `Accepted` job so I can unblock a customer without waiting for the auto-expiry.

---

## Screens / Components to Build

### Screen 1: Jobs List Page (replace `web-admin/src/pages/Jobs/Jobs.tsx`)
- Replace all mock data with real API calls to `GET /api/admin/jobs`
- **Stats bar** at the top: 4 summary cards — Total Jobs, Pending, Active (Accepted + EnRoute + InProgress), Completed/Paid
- **Filter toolbar**:
  - Text search (job ref#, customer name, provider name — debounced 300ms)
  - Status dropdown: All | Pending | Accepted | EnRoute | InProgress | Completed | Paid | Expired
  - Date range pickers: "From" and "To" (filter by `createdAt`)
  - Clear Filters button
- **Jobs table** columns: Job ID (ref#), Customer, Provider (or "Unassigned"), Category, Status badge, Created At, Amount (from `payments.transactions` — show "—" if not yet paid)
- Each row is clickable → opens Job Detail Drawer
- **Pagination**: page size 20, prev/next controls with total count display
- Loading skeleton and empty state

### Screen 2: Job Detail Drawer (`web-admin/src/pages/Jobs/JobDetailDrawer.tsx`)
- Slides in from the right (fixed, full-height drawer pattern — match the style of any existing detail drawer in Providers)
- **Header**: Job Ref# + Status badge + Close button
- **Summary section**: Customer name+ID, Provider name+ID (or Unassigned), Category, Address, Description, Created At, Accepted At, Paid At
- **Photos section**: grid of job photos (if any)
- **Status Timeline**: vertical timeline showing each `JobStatusHistory` entry — PreviousStatus → NewStatus, timestamp, changedBy
- **Rating section**: if a rating exists, show IsPositive (👍/👎), Tags, SubmittedAt, Rater type
- **Admin Actions** (bottom of drawer):
  - "Force Cancel" button — only visible when status is `Pending` or `Accepted`; opens a confirmation dialog before calling `POST /api/admin/jobs/{jobId}/force-cancel`

---

## API Endpoints Required

### GET /api/admin/jobs
- Auth: Admin JWT (`[Authorize(Policy = "AdminOnly")]`)
- Controller: create `backend/src/Khudmati.API/Controllers/AdminJobsController.cs`
- Query params:
  - `search` (string, optional) — matches against `ReferenceNumber`, customer display name, provider display name
  - `status` (string, optional) — maps to `JobStatus` enum value
  - `from` (DateTime, optional)
  - `to` (DateTime, optional)
  - `page` (int, default 1)
  - `pageSize` (int, default 20, max 50)
- Response:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "jobId": "uuid",
        "referenceNumber": "KH-20260404-0001",
        "customerId": "uuid",
        "customerName": "string",
        "providerId": "uuid | null",
        "providerName": "string | null",
        "categoryId": "string",
        "status": "Pending",
        "createdAt": "ISO8601",
        "acceptedAt": "ISO8601 | null",
        "paidAt": "ISO8601 | null",
        "amount": "decimal | null"
      }
    ],
    "totalCount": 0,
    "page": 1,
    "pageSize": 20
  }
}
```
- Business rules: No customer/provider ownership filter — admin sees all rows. JOIN to `customers.accounts` and `providers.accounts` for names. LEFT JOIN to `payments.transactions` for amount. Order by `createdAt DESC`.

### GET /api/admin/jobs/{jobId}
- Auth: Admin JWT
- Response includes all `JobDto` fields PLUS:
  - `customerName`, `providerName` (joined from respective module tables)
  - `statusHistory`: array of `{ previousStatus, newStatus, changedAt, changedBy }`
  - `photos`: array of photo URLs
  - `rating`: `{ isPositive, tags, submittedAt, raterType } | null`
  - `amount`: decimal | null (from `payments.transactions` where `jobId` matches)
- Error: `JOB_NOT_FOUND` → 404

### POST /api/admin/jobs/{jobId}/force-cancel
- Auth: Admin JWT
- No request body required
- Business rules:
  - Only allowed when `job.Status` is `Pending` or `Accepted`
  - Transitions job to `Expired` status (reuse the existing `MarkExpired()` domain method on the `Job` entity)
  - Logs a `JobStatusHistory` entry with `changedBy` = the admin's sub claim
  - Does NOT trigger payment release or provider payout
  - Fires a push notification to the customer: "Your booking [ref#] has been cancelled by the support team."
- Response: `{ "success": true, "data": { "jobId": "uuid", "newStatus": "Expired" } }`
- Errors:
  - `JOB_NOT_FOUND` → 404
  - `CANNOT_CANCEL_JOB_IN_CURRENT_STATUS` → 422 (job is already past Accepted)

---

## Backend Implementation Notes

### New Query: `GetAdminJobsQuery`
File: `Modules/Bookings/Application/Queries/GetAdminJobsQuery.cs`
- Parameters: `Search`, `Status`, `From`, `To`, `Page`, `PageSize`
- Handler builds an `IQueryable<Job>` with optional `.Where()` clauses
- JOINs to `customers.accounts` and `providers.accounts` via raw EF cross-context query (use `_context.Set<CustomerAccount>()` and `_context.Set<ProviderAccount>()` — they are on the same `AppDbContext`)
- LEFT JOINs to `payments.transactions` for amount
- Returns a new `AdminJobListDto`

### New Query: `GetAdminJobDetailQuery`
File: `Modules/Bookings/Application/Queries/GetAdminJobDetailQuery.cs`
- Eagerly loads `Photos`, `JobStatusHistory` (use `_context.Set<JobStatusHistory>().Where(h => h.JobId == jobId)`)
- Loads `Rating` via `_context.Set<Rating>().FirstOrDefaultAsync(r => r.JobId == jobId)`
- Loads `Transaction` via `_context.Set<Transaction>().FirstOrDefaultAsync(t => t.JobId == jobId)`

### New Command: `AdminForceCancelJobCommand`
File: `Modules/Bookings/Application/Commands/AdminForceCancelJobCommand.cs`
- Loads job by ID
- Validates `Status == Pending || Status == Accepted`
- Calls `job.MarkExpired()`
- Appends a `JobStatusHistory` entry with `changedBy = adminId`
- Dispatches a notification via `INotificationService` to the customer

### Repository addition
Add to `IBookingsRepository` / `BookingsRepository.cs`:
```csharp
Task<(IReadOnlyList<AdminJobSummary> Jobs, int Total)> GetAdminJobsAsync(
    string? search, JobStatus? status, DateTime? from, DateTime? to,
    int page, int pageSize, CancellationToken ct = default);
```

---

## Data Model / DB Changes
No new tables. All required data already exists:
- `bookings.jobs` — job core data
- `bookings.job_status_history` — timeline entries
- `bookings.job_photos` — photo URLs
- `bookings.ratings` — customer rating
- `payments.transactions` — amount and payment status

---

## Frontend Implementation Notes

### API layer
Create `web-admin/src/api/jobs.ts`:
```typescript
export interface AdminJobSummary { ... }      // matches GET /api/admin/jobs item shape
export interface AdminJobDetail { ... }       // matches GET /api/admin/jobs/{id}
export interface AdminJobsFilters {
  search?: string; status?: string; from?: string; to?: string; page: number; pageSize: number;
}
export async function fetchAdminJobs(filters: AdminJobsFilters): Promise<{ items: AdminJobSummary[]; totalCount: number; page: number; pageSize: number }>
export async function fetchAdminJobDetail(jobId: string): Promise<AdminJobDetail>
export async function forceCancel(jobId: string): Promise<void>
```

### State
Use local `useState` + `useEffect` in `Jobs.tsx` (no Zustand store needed — page-level state only).
Debounce the search input with a 300ms `setTimeout`.

### Component files to create/modify
| File | Action |
|---|---|
| `web-admin/src/pages/Jobs/Jobs.tsx` | Replace mock data with real API; add stats bar, date filters, pagination |
| `web-admin/src/pages/Jobs/JobDetailDrawer.tsx` | New — sliding detail panel |
| `web-admin/src/api/jobs.ts` | New — typed API functions |

`App.tsx` already registers `/jobs` — no route changes needed.
Add `/jobs/:jobId` as an optional detail route only if a full-page detail view is preferred over a drawer; **drawer is preferred**.

---

## Edge Cases & Validation
- Job with no provider (still `Pending`) shows "Unassigned" in provider column — not an error
- Job with no photos shows an empty photos section (not an error or loading state)
- Job with no rating shows "Not yet rated" in the rating section
- Force Cancel on a job in `InProgress`, `Completed`, or `Paid` returns `CANNOT_CANCEL_JOB_IN_CURRENT_STATUS` → show a toast error in the UI
- Search with no results → empty state illustration + "No jobs match your filters" message
- Date "from" must not be after "to" — validate on frontend before firing API call
- `Expired` status jobs: readonly in detail drawer, no admin actions shown

---

## Out of Scope (do not implement)
- Dispute resolution flow (feature #13)
- Manual payment refund or payout override from this screen (feature #13)
- Reassigning a job to a different provider
- Bulk actions (select multiple jobs + batch cancel)
- CSV / Excel export
- Real-time job status updates on the list via SignalR (polling on page focus is sufficient for V1)
- Super admin panel equivalent (handled separately)

---

## Acceptance Criteria
- [ ] `GET /api/admin/jobs` returns real paginated job data with optional filters; protected by `AdminOnly` policy
- [ ] `GET /api/admin/jobs/{jobId}` returns full detail including timeline, photos, rating, and amount
- [ ] `POST /api/admin/jobs/{jobId}/force-cancel` transitions a `Pending` or `Accepted` job to `Expired`, logs history, notifies customer
- [ ] Force Cancel returns `CANNOT_CANCEL_JOB_IN_CURRENT_STATUS` (422) for any other status
- [ ] Jobs list page shows live data (no mocks), status filter and search work correctly
- [ ] Stats bar shows correct counts from the same paginated query (or a separate count query)
- [ ] Job Detail Drawer opens on row click, shows all sections: summary, timeline, photos, rating, amount
- [ ] "Force Cancel" button visible only on `Pending` / `Accepted` jobs; requires confirmation before firing
- [ ] Pagination works (prev/next, page indicator, correct total)
- [ ] Empty state and loading skeleton render correctly
- [ ] No TypeScript errors; no `any` types in the API layer
