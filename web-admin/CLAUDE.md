# web-admin — Operations Admin Panel

## Run
```bash
npm install
npm run dev   # http://localhost:3001
```

## Purpose
Internal tool for the Khudmati operations team. Manages jobs, disputes, providers, and customers.
Requires `admin` or `superadmin` JWT audience.

## Stack
React 18 + TypeScript + Vite + Tailwind CSS + Zustand + Axios + TanStack Query

## Auth
- Login: `POST /api/auth/admin/login` (email + password, no OTP)
- JWT audience: `admin` (or `superadmin` if logged in as superadmin)
- Tokens stored in Zustand (`useAuthStore`) + localStorage:
  - `khudmati_admin_token` — access token
  - `khudmati_admin_role` — role string
  - `khudmati_admin_refresh_token` — refresh token
- `ProtectedRoute` checks token existence and JWT expiry (manual `atob` decode — no jwt-decode library)
- `RoleGuard` redirects to `/403` when role is insufficient

## Axios client (`src/api/client.ts`)
- Attaches `Bearer` token on every request
- On 401: attempts one refresh via `POST /api/auth/admin/refresh`, retries original request
- On refresh failure: calls `clearAuth()` + navigates to `/login`
- `setNavigate(fn)` must be called from `App.tsx` (via `NavigateSetter` component) to wire navigation

## State management
Zustand with `persist` middleware. Store: `{ token, role, adminId, setAuth, clearAuth }`.
Hydrated from localStorage on app init. Persist key: `khudmati_admin_auth`.

## Routes
| Path | Component | Notes |
|---|---|---|
| `/login` | `Login` | Public — inline error messages, no toast |
| `/403` | `Forbidden` | Shown on role mismatch |
| `/dashboard` | `Dashboard` | Default landing after login |
| `/jobs` | `Jobs` | Job management |
| `/providers` | `AllProviders` | Provider list with tier filtering |
| `/providers/verification-queue` | `VerificationQueue` | Document review queue — table → modal with approve/reject |
| `/customers` | `Customers` | Customer accounts |
| `/disputes` | `Disputes` | Two-panel dispute queue with Accept/Reject Refund |
| `/subscriptions` | `SubscriptionOverview` | Subscription stats — active subs table, MRR, churn |
| `/reminder-rules` | `ReminderRulesPage` | Admin-managed reminder interval per service category |
| `/settings` | `Settings` | Operational settings |

## Provider Verification (Feature #07)
### Verification Queue Page
- **Path**: `/providers/verification-queue`
- **Component**: `VerificationQueue.tsx`
- **API**: `GET /api/admin/providers/verification-queue`
- **Table columns**: Provider name, phone, document type, submission date, action button
- **Modal**: Click "View Documents" → full-screen modal showing front/back images (zoomable)
- **Actions**: 
  - **Approve** → `POST /api/admin/providers/{providerId}/verify-documents` with `action: 'approve'`
  - **Reject** → textarea for rejection reason (required) → POST with `action: 'reject'`
- Real-time: On approve/reject, provider receives SignalR `VerificationStatusChanged` notification

### All Providers Page
- **Path**: `/providers`
- **Component**: `AllProviders.tsx`
- **API**: `GET /api/admin/providers?tier=Active&categoryId=plumbing`
- **Filters**: Tier dropdown (Unverified/PhoneVerified/IdVerified/SkillTested/Active), category selector
- **Tier badges**: Color-coded (Active=green, SkillTested=blue, IdVerified=yellow, Unverified=gray)
- **Columns**: Name, phone, tier badge, service categories, rating, jobs completed, registration date

## Jobs Management (Feature #12)
### Jobs List Page
- **Path**: `/jobs`
- **Component**: `Jobs.tsx`
- **API**: `GET /api/admin/jobs?search=&status=&from=&to=&page=1&pageSize=20`
- **Stats bar**: 4 cards — Total Jobs, Pending, Active (Accepted+EnRoute+InProgress), Completed/Paid
- **Filter toolbar**: text search (debounced 300ms), status dropdown, date range pickers (From/To), Clear Filters button
- **Table columns**: Job ID (ref#), Customer, Provider ("Unassigned" if null), Category, Status badge, Created At, Amount ("—" if not paid)
- **Pagination**: page size 20, prev/next, total count display
- Row click → opens `JobDetailDrawer`

### Job Detail Drawer
- **Component**: `JobDetailDrawer.tsx` (slides in from right, fixed full-height)
- **API**: `GET /api/admin/jobs/{jobId}`
- **Sections**:
  - Header: Job Ref# + Status badge + Close button
  - Summary: Customer name+ID, Provider name+ID (or "Unassigned"), Category, Address, Description, timestamps
  - Photos: before/after grid (hidden if no photos)
  - Status Timeline: vertical list of `JobStatusHistory` — PreviousStatus → NewStatus, timestamp, changedBy
  - Rating: isPositive (👍/👎), tags, submittedAt, raterType (or "Not yet rated")
  - Admin Actions: "Force Cancel" button only when status is `Pending` or `Accepted`; requires confirmation dialog
- **Force Cancel**: `POST /api/admin/jobs/{jobId}/force-cancel` → transitions to `Expired`, adds `JobStatusHistory` entry with adminId as `changedBy`, sends customer notification "Your booking [ref#] has been cancelled by the support team."
- Error `CANNOT_CANCEL_JOB_IN_CURRENT_STATUS` (HTTP 422) when job is not Pending or Accepted

### API layer
- **File**: `src/api/jobs.ts`
- Exports: `AdminJobSummary`, `AdminJobDetail`, `AdminJobsFilters`, `fetchAdminJobs`, `fetchAdminJobDetail`, `forceCancel`

## Disputes Management (Feature #13)
### Disputes Page
- **Path**: `/disputes`
- **Component**: `Disputes.tsx`
- **API**: `GET /api/admin/disputes?status=&search=&page=1&pageSize=20`
- **Stats bar**: 3 chip counts — Open (amber), Resolved (green), Rejected (red)
- **Filter toolbar**: status dropdown (All / Open / Resolved / Rejected), text search (debounced 300ms, matches customer/provider name)
- **Table columns**: Dispute ID, Customer, Provider, Complaint (truncated), Status badge, Amount, Created At
- Row click → opens `DisputeDetailDrawer` (slides in from right)
- **Loading skeletons** and empty states when no disputes match

### Dispute Detail Drawer
- **API**: `GET /api/admin/disputes/{disputeId}`
- **Sections**:
  - Header: Dispute ID + Status badge + Close button
  - Parties: Customer name/ID and Provider name/ID
  - Job summary: Ref#, category, address, amount, job status
  - Photos: before/after grid
  - Status timeline: job status history
  - Complaint text (full)
- **Resolution panel** (only shown when status = `Open`):
  - Admin note textarea (min 10 chars required — buttons disabled until met)
  - **Approve Refund** button (amber) → confirmation dialog → `POST /api/admin/disputes/{id}/resolve` with `action: "approve_refund"`
  - **Reject** button (red) → confirmation dialog → same endpoint with `action: "reject"`
- Real-time: customer and provider receive `DisputeResolved` SignalR event on resolution

### API layer
- **File**: `src/api/disputes.ts`
- Exports: `AdminDisputeSummary`, `AdminDisputeDetail`, `AdminDisputesResponse`, `fetchAdminDisputes`, `fetchAdminDisputeDetail`, `resolveDispute`

## UI conventions
- Tailwind for all styling. No CSS modules, no styled-components.
- Brand blue `#1B4F72` and amber `#F39C12` as arbitrary Tailwind values.
- Error messages on forms are inline `<div>` elements — never `alert()` or toast libraries.
- English UI (operations team) — no i18n needed here.

## Subscriptions (Feature #18)
### Subscription Overview Page
- **Path**: `/subscriptions`
- **Component**: `SubscriptionOverviewPage.tsx` at `src/pages/subscriptions/SubscriptionOverviewPage.tsx`
- **API**: `GET /api/admin/subscriptions?page=1&pageSize=20`
- **Summary cards**: Total Active subscribers, MRR (Monthly Recurring Revenue in SAR), Churn this month
- **Table columns**: Provider name, Plan, Status chip (Active=green / PastDue=amber / Cancelled=red), Monthly fee, Subscribed since, Next billing date
- **Provider Detail Drawer update**: add "Subscription" section showing current plan, status, commission rate, next billing date

## Reminder Rules (Feature #19)
### Reminder Rules Page
- **Path**: `/reminder-rules`
- **Component**: `ReminderRulesPage.tsx` at `src/pages/reminders/ReminderRulesPage.tsx`
- **API**: `GET /api/admin/reminder-rules`, `PUT /api/admin/reminder-rules/{id}`
- **Table columns**: Category (Arabic name), Reminder Interval (days), Status chip (Active=green / Inactive=gray), Edit button
- **Edit modal**: Number input for interval days (min 1), Active/Inactive toggle, Save button; inline validation
- **Read-only stats column**: "Total sent this month" count per rule (derived from `scheduled_reminders`)
- Empty state message when no rules configured yet
- No delete — rules are toggled inactive, never deleted
