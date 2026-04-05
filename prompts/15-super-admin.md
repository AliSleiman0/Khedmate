# Feature: Super Admin Panel — Phase 4 Platform Management

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith (`C:\Khedmate - ANJU_Context\backend\`)
  - Entity config lives in `Program.cs` via `AppDbContext.AdditionalModelConfiguration` — never in `Khudmati.Shared`
  - Repositories use `_context.Set<T>()` — no DbSet properties on AppDbContext
  - CQRS via MediatR: commands + queries live inside the relevant module's `Application/` folder
  - Admin entities live in `Khudmati.API/Domain/` (not in a separate module)
  - Policies already defined: `AdminOnly`, `AdminOrSuperAdmin`, `SuperAdminOnly`
- Database: PostgreSQL — schema-per-module convention
  - `admins.*` — admin accounts, refresh tokens (existing)
  - `payments.*` — transactions (existing, used for financial ledger)
- Frontend: React + TypeScript + Tailwind + Zustand + TanStack Query
  - Super admin panel: `C:\Khedmate - ANJU_Context\web-superadmin\`
  - Runs on port 3002; dark theme throughout
  - API client at `src/api/client.ts` — Axios with Bearer token + refresh interceptor (already implemented, do not modify)
  - Auth store at `src/store/authStore.ts` — Zustand, persisted as `khudmati_superadmin_auth` (already implemented, do not modify)
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`

---

## Goal
Wire all six super admin pages to real backend data, build the backend endpoints and DB tables that back them, implement admin account CRUD, persist and read platform configuration, and expose financial and audit data — replacing the current hardcoded mock data throughout the panel.

---

## Platforms Affected
- [x] Web Super Admin Panel (`web-superadmin/`)
- [x] Backend API (`backend/`)

---

## User Story
As a superadmin, I want a fully functional control panel so that I can manage admin accounts, configure platform-wide settings, view the financial ledger, and review an audit trail of all admin actions — all without touching the database directly.

---

## What Is Already Scaffolded (do not recreate)

| File | Status |
|---|---|
| `web-superadmin/src/api/client.ts` | ✅ Production-ready — do not modify |
| `web-superadmin/src/store/authStore.ts` | ✅ Production-ready — do not modify |
| `web-superadmin/src/router/ProtectedRoute.tsx` | ✅ Production-ready — do not modify |
| `web-superadmin/src/router/RoleGuard.tsx` | ✅ Production-ready — do not modify |
| `web-superadmin/src/pages/Login/Login.tsx` | ✅ Production-ready — do not modify |
| `web-superadmin/src/pages/Forbidden.tsx` | ✅ Production-ready — do not modify |
| `web-superadmin/src/App.tsx` | ✅ Routing wired — do not modify |
| `web-superadmin/src/layouts/SuperAdminLayout.tsx` | ⚠️ Has one bug — fix described below |
| `web-superadmin/src/pages/Dashboard/Dashboard.tsx` | ❌ Mock data only — replace |
| `web-superadmin/src/pages/Admins/Admins.tsx` | ❌ Mock data only — replace |
| `web-superadmin/src/pages/Financials/Financials.tsx` | ❌ Mock data only — replace |
| `web-superadmin/src/pages/Audit/Audit.tsx` | ❌ Mock data only — replace |
| `web-superadmin/src/pages/Config/Config.tsx` | ❌ Local state only — replace |
| `web-superadmin/src/pages/Organizations/Organizations.tsx` | 🚫 Out of scope — leave as-is |

---

## Bug Fix Required First

**File:** `web-superadmin/src/layouts/SuperAdminLayout.tsx`

`useAuthStore(s => s.logout)` — `logout` does not exist on the store. The store action is named `clearAuth`.

Fix: replace the logout call with `clearAuth` everywhere it appears in that file.

---

## Screens / Components to Build

### 1. Dashboard — `/dashboard`
- Replace hardcoded KPI cards with real data from `GET /api/superadmin/dashboard`
- KPI cards: **Total Customers**, **Total Providers**, **Platform Revenue (MTD)**, **Active Jobs**
- Remove the fake "System Health" section (no DB backing — out of scope)
- Show a loading skeleton while fetching; show an error state if the request fails

### 2. Admins — `/admins`
- Table: `name`, `email`, `role` (`admin` | `superadmin`), `status` (Active / Revoked), `created at`
- **Create Admin** button → inline form: `name`, `email`, `password`, `role` dropdown — calls `POST /api/superadmin/admins`; password must be ≥ 8 chars, contain uppercase, lowercase, digit
- **Edit** per row → inline form to change role or reactivate a revoked admin — calls `PUT /api/superadmin/admins/{id}`
- **Revoke** per row → confirmation prompt → calls `DELETE /api/superadmin/admins/{id}` (soft-delete: sets `IsActive = false`)
- A superadmin cannot revoke themselves (compare `adminId` from auth store against the row's id)
- Pagination: 20 per page

### 3. Platform Config — `/config`
- On mount: fetch current config from `GET /api/superadmin/config` and populate the form
- Fields:
  - `CommissionRate` — number input, 1–50 (integer percent)
  - `JobTimeoutMinutes` — number input, 1–60
  - `MaxProvidersPerArea` — number input, 1–100
  - `MinRatingToRemain` — number input, 0–100 (percent positive of last 20 ratings)
  - `AutoRefundThresholdDays` — number input, 1–30
- **Save** button → `PUT /api/superadmin/config` — show inline success/error; disable button during save

### 4. Financials — `/financials`
- Summary bar: **Total Settled**, **Pending (in hold)**, **Total Refunded** — computed from filtered results
- Transactions table: `reference`, `customer name`, `provider name`, `gross amount`, `commission`, `net payout`, `status` (`Pending` | `Held` | `Released` | `Refunded`), `created at`
- Date range filter: **From** / **To** date pickers, defaults to current calendar month
- Pagination: 20 per page

### 5. Audit Log — `/audit`
- Table: `timestamp`, `admin email`, `action type`, `description`, `target entity` (e.g. `Provider #uuid`, `Config`)
- Action type colour-coded badge: `CREATE` (green), `UPDATE` (amber), `DELETE` (red), `APPROVE` (blue), `REJECT` (red)
- Filter by action type (multi-select dropdown); filter by date range
- Pagination: 20 per page

---

## Backend — New Controller

Create `backend/src/Khudmati.API/Controllers/SuperAdminController.cs`:
- All routes prefixed `api/superadmin/`
- All actions protected with `[Authorize(Policy = "SuperAdminOnly")]`
- Inject `AppDbContext` directly (no MediatR needed — these are thin read/write operations)
- Inject `ILogger<SuperAdminController>` for error logging

---

## Backend — New DB Tables

### `admins.platform_config` (single-row config table)
```sql
CREATE TABLE admins.platform_config (
  id              SERIAL  PRIMARY KEY,
  commission_rate INT     NOT NULL DEFAULT 15,       -- percent, 1–50
  job_timeout_minutes INT NOT NULL DEFAULT 2,
  max_providers_per_area INT NOT NULL DEFAULT 10,
  min_rating_to_remain INT NOT NULL DEFAULT 50,      -- percent positive
  auto_refund_threshold_days INT NOT NULL DEFAULT 1,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by_admin_id UUID REFERENCES admins.accounts(id)
);
```
Seed one row on first request: if no row exists, insert defaults.

### `admins.audit_log`
```sql
CREATE TABLE admins.audit_log (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    UUID    NOT NULL REFERENCES admins.accounts(id),
  action_type TEXT    NOT NULL,   -- 'CREATE' | 'UPDATE' | 'DELETE' | 'APPROVE' | 'REJECT'
  description TEXT    NOT NULL,
  target_type TEXT,               -- e.g. 'AdminAccount', 'PlatformConfig', 'Provider'
  target_id   TEXT,               -- stringified id of the affected entity
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Migrations
Generate EF migrations for both new tables:
```bash
cd backend
dotnet ef migrations add AddSuperAdminTables --project src/Khudmati.API --startup-project src/Khudmati.API
dotnet ef database update --project src/Khudmati.API --startup-project src/Khudmati.API
```

Add EF entity configs in `Program.cs` inside `AppDbContext.AdditionalModelConfiguration`:
```csharp
modelBuilder.Entity<PlatformConfig>(e => { e.ToTable("platform_config", "admins"); });
modelBuilder.Entity<AuditLogEntry>(e => { e.ToTable("audit_log", "admins"); });
```

---

## Backend — New Domain Entities

Create `backend/src/Khudmati.API/Domain/PlatformConfig.cs`:
```csharp
public class PlatformConfig
{
    public int Id { get; private set; }
    public int CommissionRate { get; private set; } = 15;
    public int JobTimeoutMinutes { get; private set; } = 2;
    public int MaxProvidersPerArea { get; private set; } = 10;
    public int MinRatingToRemain { get; private set; } = 50;
    public int AutoRefundThresholdDays { get; private set; } = 1;
    public DateTime UpdatedAt { get; private set; } = DateTime.UtcNow;
    public Guid? UpdatedByAdminId { get; private set; }

    private PlatformConfig() { }

    public static PlatformConfig CreateDefaults() => new();

    public void Update(int commissionRate, int jobTimeoutMinutes, int maxProvidersPerArea,
                       int minRatingToRemain, int autoRefundThresholdDays, Guid adminId)
    {
        CommissionRate = commissionRate;
        JobTimeoutMinutes = jobTimeoutMinutes;
        MaxProvidersPerArea = maxProvidersPerArea;
        MinRatingToRemain = minRatingToRemain;
        AutoRefundThresholdDays = autoRefundThresholdDays;
        UpdatedAt = DateTime.UtcNow;
        UpdatedByAdminId = adminId;
    }
}
```

Create `backend/src/Khudmati.API/Domain/AuditLogEntry.cs`:
```csharp
public class AuditLogEntry
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid AdminId { get; private set; }
    public string ActionType { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public string? TargetType { get; private set; }
    public string? TargetId { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;

    private AuditLogEntry() { }

    public static AuditLogEntry Create(Guid adminId, string actionType, string description,
                                        string? targetType = null, string? targetId = null) =>
        new() { AdminId = adminId, ActionType = actionType, Description = description,
                TargetType = targetType, TargetId = targetId };
}
```

---

## API Endpoints Required

### GET /api/superadmin/dashboard
- Auth: `SuperAdminOnly`
- Returns: platform-wide aggregates computed via SQL COUNT/SUM queries
- Response:
```json
{
  "success": true,
  "data": {
    "totalCustomers": 1240,
    "totalProviders": 318,
    "platformRevenueMtd": 15200.00,
    "activeJobs": 42
  }
}
```
- `platformRevenueMtd` = sum of `commission_amount` from `payments.transactions` where status = `Released` and `created_at` is in the current calendar month
- `activeJobs` = count of jobs in `Accepted`, `EnRoute`, or `InProgress` status

---

### GET /api/superadmin/admins?page=1&pageSize=20
- Auth: `SuperAdminOnly`
- Response:
```json
{
  "success": true,
  "data": {
    "admins": [
      { "id": "uuid", "email": "...", "role": "admin", "isActive": true, "createdAt": "..." }
    ],
    "total": 12,
    "page": 1,
    "pageSize": 20
  }
}
```

### POST /api/superadmin/admins
- Auth: `SuperAdminOnly`
- Request: `{ "email": "string", "password": "string", "role": "admin" | "superadmin" }`
- Validation: email must be unique in `admins.accounts`; password ≥ 8 chars, at least one uppercase, one lowercase, one digit
- Action: BCrypt hash password; insert new `AdminAccount`; write audit log entry: `CREATE / AdminAccount / {id}`
- Response: `{ "success": true, "data": { "id": "uuid", "email": "...", "role": "..." } }`
- Error codes: `EMAIL_ALREADY_EXISTS`, `INVALID_PASSWORD_FORMAT`

### PUT /api/superadmin/admins/{id}
- Auth: `SuperAdminOnly`
- Request: `{ "role": "admin" | "superadmin", "isActive": true | false }`
- Guard: cannot update your own record (compare `{id}` against caller's sub claim)
- Action: update `AdminAccount`; write audit log: `UPDATE / AdminAccount / {id}`
- Response: `{ "success": true, "data": { "id": "...", "role": "...", "isActive": true } }`
- Error codes: `ADMIN_NOT_FOUND`, `CANNOT_MODIFY_SELF`

### DELETE /api/superadmin/admins/{id}
- Auth: `SuperAdminOnly`
- Soft-delete only: sets `IsActive = false`, invalidates all active refresh tokens for that admin
- Guard: cannot revoke yourself
- Action: write audit log: `DELETE / AdminAccount / {id}`
- Response: `{ "success": true }`
- Error codes: `ADMIN_NOT_FOUND`, `CANNOT_MODIFY_SELF`, `ALREADY_REVOKED`

---

### GET /api/superadmin/config
- Auth: `SuperAdminOnly`
- Seeds the single config row if it doesn't exist yet; returns current values
- Response:
```json
{
  "success": true,
  "data": {
    "commissionRate": 15,
    "jobTimeoutMinutes": 2,
    "maxProvidersPerArea": 10,
    "minRatingToRemain": 50,
    "autoRefundThresholdDays": 1,
    "updatedAt": "2026-04-04T10:00:00Z"
  }
}
```

### PUT /api/superadmin/config
- Auth: `SuperAdminOnly`
- Request: same shape as response above (minus `updatedAt`)
- Validation: all fields within declared ranges (commissionRate 1–50, jobTimeoutMinutes 1–60, etc.)
- Action: update the single config row; write audit log: `UPDATE / PlatformConfig / 1`
- Response: `{ "success": true, "data": { ...updated config } }`
- Error codes: `INVALID_CONFIG_VALUE`

---

### GET /api/superadmin/financials?from=2026-01-01&to=2026-04-04&page=1&pageSize=20
- Auth: `SuperAdminOnly`
- Reads from `payments.transactions` joined to `bookings.jobs` → customer name, provider name
- Response:
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalSettled": 12500.00,
      "totalPending": 3400.00,
      "totalRefunded": 800.00
    },
    "transactions": [
      {
        "id": "uuid",
        "referenceNumber": "KHD-ABC123",
        "customerName": "Ahmad Ali",
        "providerName": "Mohammed Saeed",
        "grossAmount": 250.00,
        "commissionAmount": 37.50,
        "netPayout": 212.50,
        "status": "Released",
        "createdAt": "2026-04-03T14:22:00Z"
      }
    ],
    "total": 87,
    "page": 1,
    "pageSize": 20
  }
}
```
- `from` / `to` default to first and last day of the current calendar month if not supplied
- `summary` is computed across the **entire date range** (not just the current page)

---

### GET /api/superadmin/audit?page=1&pageSize=20&actionType=CREATE,UPDATE&from=2026-01-01&to=2026-04-04
- Auth: `SuperAdminOnly`
- Reads from `admins.audit_log` joined to `admins.accounts` for admin email
- `actionType` is a comma-separated filter (optional)
- Response:
```json
{
  "success": true,
  "data": {
    "entries": [
      {
        "id": "uuid",
        "adminEmail": "superadmin@khudmati.com",
        "actionType": "UPDATE",
        "description": "Updated platform commission rate to 18%",
        "targetType": "PlatformConfig",
        "targetId": "1",
        "createdAt": "2026-04-04T10:30:00Z"
      }
    ],
    "total": 54,
    "page": 1,
    "pageSize": 20
  }
}
```

---

## Audit Log — Write Points

Write an `AuditLogEntry` (using `_context.Set<AuditLogEntry>().Add(...)`) in these operations:

| Action | Type | Description template |
|---|---|---|
| Create admin | `CREATE` | `"Created admin account {email} with role {role}"` |
| Update admin (role change) | `UPDATE` | `"Changed role of {email} from {old} to {new}"` |
| Update admin (activate) | `UPDATE` | `"Reactivated admin account {email}"` |
| Revoke admin | `DELETE` | `"Revoked admin account {email}"` |
| Update config | `UPDATE` | `"Updated platform config: commission={rate}%, timeout={min}min"` |

---

## Frontend — API Client File

Create `web-superadmin/src/api/superadmin.ts`:
```typescript
import client from './client'

export const superAdminApi = {
  getDashboard: () =>
    client.get('/api/superadmin/dashboard').then(r => r.data.data),

  getAdmins: (page: number) =>
    client.get('/api/superadmin/admins', { params: { page, pageSize: 20 } }).then(r => r.data.data),

  createAdmin: (body: { email: string; password: string; role: string }) =>
    client.post('/api/superadmin/admins', body).then(r => r.data.data),

  updateAdmin: (id: string, body: { role: string; isActive: boolean }) =>
    client.put(`/api/superadmin/admins/${id}`, body).then(r => r.data.data),

  revokeAdmin: (id: string) =>
    client.delete(`/api/superadmin/admins/${id}`).then(r => r.data),

  getConfig: () =>
    client.get('/api/superadmin/config').then(r => r.data.data),

  saveConfig: (body: object) =>
    client.put('/api/superadmin/config', body).then(r => r.data.data),

  getFinancials: (params: { from: string; to: string; page: number }) =>
    client.get('/api/superadmin/financials', { params: { ...params, pageSize: 20 } }).then(r => r.data.data),

  getAudit: (params: { from: string; to: string; page: number; actionType?: string }) =>
    client.get('/api/superadmin/audit', { params: { ...params, pageSize: 20 } }).then(r => r.data.data),
}
```

---

## Frontend — Page Implementations

### All pages must:
- Use `useQuery` (TanStack Query) for fetching — set `staleTime: 30_000`
- Use `useMutation` for writes (create, update, delete, save)
- Show an inline error message (no toast library) if any request fails
- Display a loading skeleton while the initial query is in flight
- Use `queryClient.invalidateQueries` to refresh the relevant query after a successful mutation
- Support RTL layout (the panel is shown to Arabic speakers too): use `dir="rtl"` on table rows and form labels where Arabic is used

### Dashboard
- Import `superAdminApi.getDashboard`; use `useQuery(['dashboard'])`
- KPI value: display numbers with Arabic-locale `toLocaleString('ar-SA')`
- On load error: inline red message "تعذّر تحميل إحصائيات المنصة"

### Admins
- `useQuery(['admins', page])` + `useMutation` for create / update / revoke
- Revoke button: show a `window.confirm`-style inline confirmation (a small `Are you sure?` row that expands, styled in Tailwind)
- Password field in create form: show/hide toggle
- Form validation runs client-side before submit; show field-level error text
- Disable the `Revoke` and `Edit` buttons for the currently logged-in admin (compare row `id` with Zustand `adminId`)

### Config
- `useQuery(['config'])` on mount to populate form
- Keep a local `isDirty` flag; disable Save when nothing changed
- After successful save: show inline "✓ تم الحفظ" for 2 seconds then clear

### Financials
- Date range state: default `from = start of current month`, `to = today`
- `useQuery(['financials', from, to, page])` — refetch when date range changes
- Summary cards above the table (computed from response, not recalculated locally)
- Status badge colours: `Released` = green, `Held` = amber, `Pending` = grey, `Refunded` = red

### Audit Log
- `useQuery(['audit', from, to, page, actionType])` — refetch when any filter changes
- Multi-select action type filter: `CREATE`, `UPDATE`, `DELETE`, `APPROVE`, `REJECT`
- Action badge colours: `CREATE` = green, `UPDATE` = amber, `DELETE` = red, `APPROVE` = blue, `REJECT` = red

---

## Data Model / DB Changes

| Table | Schema | New? |
|---|---|---|
| `platform_config` | `admins` | ✅ New |
| `audit_log` | `admins` | ✅ New |
| `accounts` | `admins` | Existing — no changes |
| `transactions` | `payments` | Existing — read only |
| `jobs` | `bookings` | Existing — read only |

---

## Out of Scope (do not implement)

- Organizations management — no DB model exists; multi-tenancy is a V2 concept
- System health monitoring (uptime, DB connections, queue depth) — no DB backing
- Real-time dashboard auto-refresh via SignalR
- CSV / Excel export for financials or audit log
- Email notifications when a new admin account is created
- Subscription or billing management

---

## Acceptance Criteria

- [ ] `SuperAdminLayout` logout button calls `clearAuth` (bug fixed)
- [ ] Dashboard KPI cards display real counts/revenue from the database, not hardcoded values
- [ ] Superadmin can create a new admin account with email + password + role; duplicate email returns `EMAIL_ALREADY_EXISTS`
- [ ] Superadmin can change an admin's role or reactivate a revoked account via the Edit flow
- [ ] Superadmin can revoke (soft-delete) an admin; revoked admin's refresh tokens are invalidated; superadmin cannot revoke themselves
- [ ] Platform config is read from DB on page load; saving updates the DB row and writes an audit entry
- [ ] Financials table shows real `payments.transactions` rows with correct customer/provider names; summary totals are correct
- [ ] Date range filter on Financials refetches data and updates summary cards
- [ ] Audit log table shows real `admins.audit_log` rows with admin email and action badge
- [ ] Audit log action-type filter and date range filter refetch correctly
- [ ] All pages show loading skeleton during fetch and inline error message on failure
- [ ] All admin CRUD mutations write a corresponding audit log entry
- [ ] All new backend endpoints return `{ success: false, error: "SCREAMING_SNAKE_CASE" }` on failure
- [ ] EF migrations for `platform_config` and `audit_log` tables generated and applied
