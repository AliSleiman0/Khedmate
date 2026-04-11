# web-superadmin — Super Admin Panel

## Run
```bash
npm install
npm run dev   # http://localhost:3002
```

## Purpose
Platform-level management for Khudmati owners/superadmins. Controls organizations, admin accounts, financial config, audit logs, and global platform settings. Requires `superadmin` JWT audience.

## Stack
React 18 + TypeScript + Vite + Tailwind CSS + Zustand + Axios + TanStack Query
Dark theme by default (distinct from web-admin's light theme).

## Auth
- Same login endpoint as web-admin: `POST /api/auth/admin/login`
- JWT audience must be `superadmin` — attempting to log in as `admin` role will still succeed at the API but the superadmin panel's `ProtectedRoute` will redirect to `/403`
- Tokens stored in Zustand + localStorage:
  - `khudmati_admin_token`
  - `khudmati_admin_role`
  - `khudmati_superadmin_refresh_token`
- Persist key: `khudmati_superadmin_auth`

## Axios client (`src/api/client.ts`)
Identical structure to web-admin client. Refresh token key in localStorage: `khudmati_superadmin_refresh_token`.

## API client
`src/api/superadmin.ts` — all super admin API calls: `getDashboard`, `getAdmins`, `createAdmin`, `updateAdmin`, `revokeAdmin`, `getConfig`, `saveConfig`, `getFinancials`, `getAudit`, `getSubscriptionPlans`, `updateSubscriptionPlan`. Uses `src/api/client.ts` Axios instance (do not modify `client.ts`).

## Routes
| Path | Component | Notes |
|---|---|---|
| `/login` | `Login` | Subtitle: "بوابة الإدارة العليا" |
| `/403` | `Forbidden` | Shown when role is `admin` (not `superadmin`) |
| `/dashboard` | `Dashboard` | Platform-wide KPIs (TanStack Query, 30s stale time) |
| `/admins` | `Admins` | Admin account CRUD — create with password, edit role/status, revoke; self-edit protected |
| `/financials` | `Financials` | Revenue, commissions, payouts — date-range filter, summary cards, paginated table |
| `/audit` | `Audit` | Full audit log — date-range + action-type filter, paginated |
| `/config` | `Config` | Commission rate, job timeout, max providers per area, min rating, auto-refund threshold |
| `/plans` | `PlansPage` | Subscription plan config — edit monthly fee, commission rate, priority delay, Stripe price ID |

## UI conventions
Same as web-admin (Tailwind, inline errors, no toast libraries) but dark theme.
Config page (`/config`) is where platform-wide settings like `CommissionRate` and `JobTimeoutMinutes` are managed.

## Subscription Plan Config (Feature #18)
### Plans Page
- **Path**: `/plans`
- **Component**: `PlansPage.tsx` at `src/pages/plans/PlansPage.tsx`
- **API**: `GET /api/superadmin/subscription-plans` (list), `PATCH /api/superadmin/subscription-plans/{id}` (update)
- **Editable fields**: Monthly fee (SAR), Commission rate (%), Priority delay (seconds), Stripe Price ID, Active toggle
- Inline editing — save button per row; no modal needed
- Toggle `is_active` to hide/show the subscribe button in the provider app without a code deploy
- Stripe Price ID field links the plan to the Stripe price object for recurring billing

## Key difference from web-admin
- Only `superadmin` role can access this panel — `ProtectedRoute` enforces this by default.
- Admin seeding: the first superadmin account is seeded on API startup from `appsettings.Development.json` (`SeedAdmin.Email` / `SeedAdmin.Password`). Default: `superadmin@khudmati.com` / `Admin@12345`.
