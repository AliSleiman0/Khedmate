# Feature: Admin Provider Management (#14)
**Phase 3 — Operations**

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module: `providers.*`)
- Real-time: SignalR
- Frontend: React + TypeScript + Tailwind CSS (`web-admin/`)
- Brand: Blue `#1B4F72`, Amber `#F39C12` | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: `C:\Khedmate - ANJU_Context`
- Prerequisites: Features #01–#13 must be implemented. The `providers.*` tables exist including `providers.providers`, `providers.tier_history`, `providers.document_submissions`, and `providers.rating_stats`.

## Goal
Replace the mock-data `Providers.tsx` and upgrade the bare-bones `AllProviders.tsx` into a full operational provider management hub — giving the admin team a paginated, searchable provider list, a rich per-provider detail drawer, and the ability to suspend or reinstate any provider account.

## Platforms Affected
- [x] Web Admin Panel (`web-admin/`)
- [x] Backend (`backend/`) — new domain method, DB migration, new queries and commands

---

## User Stories
- As an **admin**, I want to browse all providers with real data, filtered by tier, online status, suspension status, or name/phone search so I can monitor the provider pool.
- As an **admin**, I want to drill into a specific provider and see their full profile, rating stats, tier history, and document submissions so I can make informed operational decisions.
- As an **admin**, I want to suspend an active provider account with a mandatory reason so I can remove bad actors from the platform immediately.
- As an **admin**, I want to reinstate a previously suspended provider so they can resume accepting jobs.

---

## Screens / Components to Build

### Screen 1: Provider List (upgrade `web-admin/src/pages/Providers/AllProviders.tsx`)

Completely replace the existing bare-bones implementation. Keep the component name `AllProviders` and its location.

**Stats bar** at top — 4 summary cards (call `GET /api/admin/providers/stats`):
- Total Providers
- Active (tier = `Active`, not suspended)
- Pending Verification (tier = `Unverified` | `PhoneVerified` | `IdVerified` | `SkillTested`)
- Suspended

**Filter toolbar** (all combinable, applied live on change):
- Text search input (debounced 300ms) — matches against provider `fullName` and `phone`
- Tier dropdown: All | Unverified | PhoneVerified | IdVerified | SkillTested | Active
- Online status toggle: All | Online | Offline
- Suspended toggle: All | Suspended | Active (not suspended)
- Clear Filters button (resets everything)

**Providers table** columns (match the Tailwind table style used in `web-admin/src/pages/Jobs/Jobs.tsx`):
- Avatar initial + Full Name
- Phone
- Email (show "—" if null)
- Tier badge (colour-coded: Unverified=grey, PhoneVerified=blue, IdVerified=purple, SkillTested=amber, Active=green)
- Rating (show % positive, e.g. "94%" with a thumbs-up icon; show "—" if no ratings yet)
- Jobs Completed
- Online status dot (green = online, grey = offline)
- Suspended badge (show red "Suspended" pill only if `isSuspended = true`)
- Joined At

Each row is clickable → opens `ProviderDetailDrawer` for that provider.

**Pagination**: page size 20, prev/next controls with total count.

Loading skeleton (6 placeholder rows) and empty state ("No providers match your filters").

---

### Screen 2: Provider Detail Drawer (new `web-admin/src/pages/Providers/ProviderDetailDrawer.tsx`)

Follows the same pattern as `web-admin/src/pages/Jobs/JobDetailDrawer.tsx` — slides in from the right, full-height, fixed overlay. Fetches data from `GET /api/admin/providers/{providerId}` on open.

**Header:** Provider full name + Tier badge + Close (×) button. Show a red "Suspended" pill next to the tier badge if suspended.

**Section 1 — Profile:**
- Avatar (large initials circle, brand blue background)
- Full Name, Phone, Email
- Service Categories (tag pills)
- Joined At, last seen online (from `isOnline` flag — show "Currently Online" in green or "Offline" in grey)

**Section 2 — Rating Stats** (from `providers.rating_stats`):
- Positive Rate (large percentage, e.g. "94%") with progress bar
- Total Ratings | Positive count | Negative count
- Top Tags (displayed as small grey pills, e.g. "Professional", "On Time")
- Show "No ratings yet" state if `totalRatings == 0`

**Section 3 — Tier & Verification History** (from `providers.tier_history`):
- Vertical timeline — each entry shows: `PreviousTier → NewTier`, `ChangedAt`, `Reason` (if any)
- Most recent entry at top

**Section 4 — Document Submissions** (from `providers.document_submissions`):
- List each submission: Document Type, Submitted At, Status badge (PendingReview=amber, Approved=green, Rejected=red)
- If status is Rejected, show `RejectionReason` in a red sub-line
- Show "No documents submitted" empty state if list is empty

**Section 5 — Admin Actions** (fixed at the bottom of the drawer):
- If `isSuspended == false`:
  - "Suspend Provider" button (red/destructive style)
  - Clicking it opens a confirmation modal with a **mandatory reason** textarea (min 10 chars):
    - Title: "Suspend Provider Account"
    - Body: "This will immediately remove the provider from the job pool. They will not be able to accept new jobs until reinstated. Please provide a reason."
    - Confirm button: "Confirm Suspension" (red)
    - Cancel button
  - On confirm: call `POST /api/admin/providers/{providerId}/suspend`
- If `isSuspended == true`:
  - "Reinstate Provider" button (green style)
  - Clicking it opens a smaller confirmation dialog (no reason required):
    - "Are you sure you want to reinstate this provider? They will be able to accept jobs again."
    - Confirm button: "Reinstate" (green)
  - On confirm: call `POST /api/admin/providers/{providerId}/reinstate`
- After either action: close modal, refresh the drawer data and update the provider row in the list

---

## API Endpoints Required

### GET /api/admin/providers/stats
- Auth: Admin JWT (`[Authorize(Policy = "AdminOnly")]`)
- Controller: add to `backend/src/Khudmati.API/Controllers/AdminProvidersController.cs`
- No query params
- Response:
```json
{
  "success": true,
  "data": {
    "total": 120,
    "active": 85,
    "pendingVerification": 30,
    "suspended": 5
  }
}
```

---

### GET /api/admin/providers (upgrade existing)
- Auth: Admin JWT
- Current implementation in `AdminProvidersController.cs` supports `tier` and `categoryId`. Extend it to also support:
  - `search` (string, optional) — matches against `FullName` (case-insensitive `ILIKE`) and `Phone` (exact prefix match)
  - `isOnline` (bool, optional) — filter by `Provider.IsOnline`
  - `isSuspended` (bool, optional) — filter by `Provider.IsSuspended`
- Response shape: extend `ProviderAdminDto` to include `isSuspended: bool`
- Keep existing `tier`, `categoryId`, `page`, `pageSize` params

---

### GET /api/admin/providers/{providerId}
- Auth: Admin JWT
- Controller: add to `AdminProvidersController.cs`
- Response:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "fullName": "string",
    "phone": "string",
    "email": "string | null",
    "tier": "Active",
    "serviceCategories": ["Cleaning", "Plumbing"],
    "isOnline": true,
    "isSuspended": false,
    "jobsCompleted": 142,
    "createdAt": "ISO8601",
    "ratingStats": {
      "totalRatings": 130,
      "positiveCount": 122,
      "negativeCount": 8,
      "positiveRate": 93.8,
      "topTags": ["Professional", "On Time", "Clean Work"]
    },
    "tierHistory": [
      {
        "previousTier": "SkillTested",
        "newTier": "Active",
        "changedBy": "uuid",
        "changedAt": "ISO8601",
        "reason": "Documents verified and skill test passed"
      }
    ],
    "documentSubmissions": [
      {
        "id": "uuid",
        "documentType": "NationalId",
        "status": "Approved",
        "submittedAt": "ISO8601",
        "reviewedAt": "ISO8601",
        "rejectionReason": null
      }
    ]
  }
}
```

---

### POST /api/admin/providers/{providerId}/suspend
- Auth: Admin JWT
- Controller: add to `AdminProvidersController.cs`
- Request: `{ "reason": "string (required, min 10 chars)" }`
- Business rules:
  - Cannot suspend an already-suspended provider → return `PROVIDER_ALREADY_SUSPENDED`
  - Sets `Provider.IsSuspended = true` and records `SuspendedReason` + `SuspendedAt` + `SuspendedBy`
  - Sends a SignalR notification to `provider-{providerId}` group: event `AccountSuspended`, payload `{ reason }`
- Response: `{ "success": true, "data": { "status": "suspended" } }`

---

### POST /api/admin/providers/{providerId}/reinstate
- Auth: Admin JWT
- Controller: add to `AdminProvidersController.cs`
- Request: (no body)
- Business rules:
  - Cannot reinstate a provider that is not suspended → return `PROVIDER_NOT_SUSPENDED`
  - Sets `Provider.IsSuspended = false`, clears `SuspendedReason` / `SuspendedAt` / `SuspendedBy`
  - Sends a SignalR notification to `provider-{providerId}` group: event `AccountReinstated`, payload `{}`
- Response: `{ "success": true, "data": { "status": "reinstated" } }`

---

## Data Model / DB Changes

### Migration: Add suspension fields to `providers.providers`

Add the following columns to the `providers.providers` table via a new EF migration named `AddProviderSuspension`:

```sql
ALTER TABLE providers.providers
  ADD COLUMN is_suspended        BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN suspended_reason    TEXT,
  ADD COLUMN suspended_at        TIMESTAMP WITH TIME ZONE,
  ADD COLUMN suspended_by        UUID REFERENCES admins.admins(id);
```

### Provider entity changes (`Modules/Providers/Khudmati.Modules.Providers/Domain/Entities/Provider.cs`)

Add the following properties:
```csharp
public bool IsSuspended { get; private set; } = false;
public string? SuspendedReason { get; private set; }
public DateTime? SuspendedAt { get; private set; }
public Guid? SuspendedBy { get; private set; }
```

Add domain methods:
```csharp
public void Suspend(Guid adminId, string reason)
{
    if (IsSuspended)
        throw new InvalidOperationException("Provider is already suspended.");
    IsSuspended = true;
    SuspendedReason = reason;
    SuspendedAt = DateTime.UtcNow;
    SuspendedBy = adminId;
    SetUpdated();
}

public void Reinstate()
{
    if (!IsSuspended)
        throw new InvalidOperationException("Provider is not suspended.");
    IsSuspended = false;
    SuspendedReason = null;
    SuspendedAt = null;
    SuspendedBy = null;
    SetUpdated();
}
```

### EF configuration (in `Program.cs` → `AppDbContext.AdditionalModelConfiguration`)

Add the new columns to the existing `providers.providers` entity configuration:
```csharp
builder.Entity<Provider>()
    .Property(p => p.IsSuspended).HasColumnName("is_suspended");
builder.Entity<Provider>()
    .Property(p => p.SuspendedReason).HasColumnName("suspended_reason");
builder.Entity<Provider>()
    .Property(p => p.SuspendedAt).HasColumnName("suspended_at");
builder.Entity<Provider>()
    .Property(p => p.SuspendedBy).HasColumnName("suspended_by");
```

---

## New Command/Query Files

### `Modules/Providers/Khudmati.Modules.Providers/Application/Commands/SuspendProviderCommand.cs`
- Record: `SuspendProviderCommand(Guid AdminId, Guid ProviderId, string Reason)`
- Handler: load Provider, call `provider.Suspend(adminId, reason)`, save, publish `ProviderSuspendedEvent` (for SignalR hub to handle)

### `Modules/Providers/Khudmati.Modules.Providers/Application/Commands/ReinstateProviderCommand.cs`
- Record: `ReinstateProviderCommand(Guid AdminId, Guid ProviderId)`
- Handler: load Provider, call `provider.Reinstate()`, save, publish `ProviderReinstatedEvent`

### `Modules/Providers/Khudmati.Modules.Providers/Application/Queries/GetProviderDetailAdminQuery.cs`
- Record: `GetProviderDetailAdminQuery(Guid ProviderId)`
- Returns a `ProviderDetailAdminDto` containing profile + `ProviderRatingStats` (left join — null if no stats row) + `List<TierHistory>` + `List<DocumentSubmission>`
- Place the DTO in `Application/DTOs/ProviderDetailAdminDto.cs`

### `Modules/Providers/Khudmati.Modules.Providers/Application/Queries/GetProviderStatsAdminQuery.cs`
- Record: `GetProviderStatsAdminQuery()`
- Returns counts: Total, Active (Tier=Active AND IsSuspended=false), PendingVerification (Tier < Active), Suspended (IsSuspended=true)

### Update `GetAllProvidersQuery.cs`
- Add `string? Search`, `bool? IsOnline`, `bool? IsSuspended` parameters
- Apply `ILIKE` filter on `FullName` and prefix filter on `Phone` when `Search` is provided
- Apply `IsOnline` and `IsSuspended` filters when provided
- Extend `ProviderAdminDto` to include `IsSuspended`

---

## SignalR Events

| Event | Fired when | Target Group | Payload |
|---|---|---|---|
| `AccountSuspended` | Admin suspends provider | `provider-{providerId}` | `{ reason: string }` |
| `AccountReinstated` | Admin reinstates provider | `provider-{providerId}` | `{}` |

Handle these events in the existing `NotificationHub` (or whichever SignalR hub handles provider personal groups). The provider mobile app should listen for `AccountSuspended` and display a full-screen message: "تم تعليق حسابك. يرجى التواصل مع الدعم." (Your account has been suspended. Please contact support.)

---

## Edge Cases & Validation

- Suspending an already-suspended provider → return error `PROVIDER_ALREADY_SUSPENDED`
- Reinstating a non-suspended provider → return error `PROVIDER_NOT_SUSPENDED`
- Suspending a provider who has an active job (status `Accepted`, `EnRoute`, or `InProgress`): **do not block the suspension** — the suspension takes effect for new jobs only; ongoing jobs proceed normally
- `reason` is required on suspend (min 10 chars) — validate at API level before hitting the command
- `GetProviderDetailAdminQuery` — if `ProviderRatingStats` row does not exist for the provider, return `ratingStats: null`; UI shows "No ratings yet"
- `AllProviders.tsx` stats bar: debounce the stats card refetch when filters change (re-fetch stats only when the suspend/reinstate drawer action completes, not on every filter keystroke)

---

## Out of Scope (do not implement)
- Provider mobile app changes beyond receiving the `AccountSuspended` / `AccountReinstated` SignalR events
- Bulk suspend/reinstate
- Suspension history log (just the current suspension state is sufficient for V1)
- Admin ability to manually set a provider's verification tier (tier changes come from the verification queue in feature #07)
- Provider earnings or payout management (covered separately)

---

## File Locations Summary

| File | Action |
|---|---|
| `web-admin/src/pages/Providers/AllProviders.tsx` | Rewrite — replace bare implementation with full list |
| `web-admin/src/pages/Providers/ProviderDetailDrawer.tsx` | Create new |
| `backend/src/Khudmati.API/Controllers/AdminProvidersController.cs` | Extend — add stats, detail, suspend, reinstate endpoints |
| `backend/src/Modules/Providers/.../Domain/Entities/Provider.cs` | Extend — add `IsSuspended` fields + `Suspend()` / `Reinstate()` methods |
| `backend/src/Modules/Providers/.../Application/Commands/SuspendProviderCommand.cs` | Create new |
| `backend/src/Modules/Providers/.../Application/Commands/ReinstateProviderCommand.cs` | Create new |
| `backend/src/Modules/Providers/.../Application/Queries/GetProviderDetailAdminQuery.cs` | Create new |
| `backend/src/Modules/Providers/.../Application/Queries/GetProviderStatsAdminQuery.cs` | Create new |
| `backend/src/Modules/Providers/.../Application/Queries/GetAllProvidersQuery.cs` | Extend — add search, isOnline, isSuspended params |
| `backend/src/Modules/Providers/.../Application/DTOs/ProviderDetailAdminDto.cs` | Create new |
| `backend/src/Khudmati.API/Program.cs` | Add EF column mappings for new suspension fields |
| DB migration `AddProviderSuspension` | Create — adds 4 columns to `providers.providers` |

---

## Acceptance Criteria
- [ ] Stats bar on AllProviders shows correct live counts (Total, Active, Pending Verification, Suspended) from the API
- [ ] Searching by name or phone filters the provider list in real time (debounced)
- [ ] Tier, online status, and suspended filters all work independently and in combination
- [ ] Clicking any provider row opens the detail drawer with correct profile, rating stats, tier history, and document submissions
- [ ] Suspending a provider with a reason succeeds; the provider immediately receives a `AccountSuspended` SignalR event
- [ ] Attempting to suspend an already-suspended provider returns `PROVIDER_ALREADY_SUSPENDED`
- [ ] Reinstating a suspended provider succeeds; the provider receives a `AccountReinstated` SignalR event
- [ ] The provider's `IsSuspended` status and the `Suspended` badge update correctly in the list and drawer after each action
- [ ] `GET /api/admin/providers/{providerId}` with a missing ID returns 404
- [ ] All UI elements respect Tailwind RTL and match the brand palette (`#1B4F72` / `#F39C12`)
- [ ] EF migration runs cleanly with no data loss on the existing `providers.providers` table
