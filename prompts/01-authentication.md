# Feature: Authentication — Customer, Provider & Admin

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR
- Frontend(s): Flutter (mobile-customer, mobile-provider) + React TypeScript (web-admin, web-superadmin)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context

## Goal
Implement the full authentication system for all three user types — customers, providers, and admins. This is the foundation every other feature depends on: registration with phone/email OTP verification, login, JWT issuance per audience, and token refresh.

## Platforms Affected
- [x] Customer Mobile App (Flutter)
- [x] Provider Mobile App (Flutter)
- [x] Web Admin Panel (React + TypeScript)
- [x] Web Super Admin Panel (React + TypeScript)
- [ ] Web Landing Page (no auth needed)

---

## User Stories

- As a **customer**, I want to register with my mobile number or email, verify via OTP, and log in so I can book services.
- As a **provider**, I want to register with my mobile number, verify via OTP, and log in so I can receive and manage job requests.
- As an **admin**, I want to log in with email and password (no OTP) so I can access the admin panel.
- As any **user**, I want my session to stay active via a refresh token so I don't have to log in repeatedly.

---

## Backend

### Module
All auth logic lives in two modules:
- `Modules/Customers/Khudmati.Modules.Customers/` — customer registration & login
- `Modules/Providers/Khudmati.Modules.Providers/` — provider registration & login
- `Khudmati.API/Controllers/Auth/` — admin login (thin, no module needed)

### JWT Design
Issue **three distinct token types** with separate audiences. Enforce audience on every protected endpoint.

| User Type | Audience claim | Expiry |
|---|---|---|
| Customer | `customer` | 15 min (access) / 30 days (refresh) |
| Provider | `provider` | 15 min (access) / 30 days (refresh) |
| Admin | `admin` | 60 min (access) / 8 hours (refresh) |
| Super Admin | `superadmin` | 60 min (access) / 8 hours (refresh) |

Store refresh tokens in the DB (hashed). One active refresh token per user. Issuing a new one invalidates the old one.

---

## API Endpoints

### Customer Auth

#### POST /api/customers/auth/register
- Auth: Public
- Request: `{ "phone": "string", "email": "string", "fullName": "string", "password": "string" }`
- Response: `{ "success": true, "data": { "message": "OTP sent to phone/email" } }`
- Business rules:
  - Phone is required; email is optional
  - Hash password with BCrypt before storing
  - Generate a 6-digit OTP, store hashed with 10-minute expiry in `customers.otp_verifications`
  - Send OTP via SMS (phone) or email — use a stub/log for v1, real provider later
  - Do NOT return the OTP in the response

#### POST /api/customers/auth/verify-otp
- Auth: Public
- Request: `{ "phone": "string", "otp": "string" }`
- Response: `{ "success": true, "data": { "accessToken": "string", "refreshToken": "string", "customer": { "id", "fullName", "phone", "email" } } }`
- Business rules:
  - Validate OTP against hashed value, check not expired
  - Mark customer as verified (`is_verified = true`)
  - Delete used OTP record
  - Issue JWT with audience `customer` + refresh token

#### POST /api/customers/auth/login
- Auth: Public
- Request: `{ "phone": "string", "password": "string" }`
- Response: `{ "success": true, "data": { "accessToken": "string", "refreshToken": "string", "customer": { ... } } }`
- Business rules:
  - If `is_verified = false` → return `400` with error `"EMAIL_NOT_VERIFIED"` (do not say "wrong password")
  - If password wrong → return `401` with error `"INVALID_CREDENTIALS"`
  - On success → issue new JWT + refresh token

#### POST /api/customers/auth/resend-otp
- Auth: Public
- Request: `{ "phone": "string" }`
- Response: `{ "success": true, "data": { "message": "OTP resent" } }`
- Business rules: Rate limit — max 3 resends per phone per 10 minutes

#### POST /api/customers/auth/refresh
- Auth: Public
- Request: `{ "refreshToken": "string" }`
- Response: `{ "success": true, "data": { "accessToken": "string", "refreshToken": "string" } }`
- Business rules: Validate refresh token → issue new access + refresh token pair (rotate)

#### POST /api/customers/auth/logout
- Auth: Customer JWT
- Request: (empty body)
- Response: `{ "success": true }`
- Business rules: Invalidate the current refresh token in DB

---

### Provider Auth
Mirror all customer endpoints under `/api/providers/auth/` with the same structure. Differences:
- Provider audience is `provider`
- Provider table is `providers.accounts` (not `customers.accounts`)
- Provider registration also accepts `serviceCategories: string[]` (store for later, no validation needed in v1)

---

### Admin Auth

#### POST /api/auth/admin/login
- Auth: Public
- Request: `{ "email": "string", "password": "string" }`
- Response: `{ "success": true, "data": { "accessToken": "string", "refreshToken": "string", "admin": { "id", "email", "role" } } }`
- Business rules:
  - No OTP for admins — email + password only
  - Role field: `"admin"` or `"superadmin"` → sets JWT audience accordingly
  - Admins are seeded manually (no self-registration endpoint)

#### POST /api/auth/admin/refresh
- Same pattern as customer refresh

#### POST /api/auth/admin/logout
- Auth: Admin JWT or SuperAdmin JWT

---

## Data Model

### customers schema

```sql
-- customers.accounts
CREATE TABLE customers.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- customers.otp_verifications
CREATE TABLE customers.otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES customers.accounts(id) ON DELETE CASCADE,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- customers.refresh_tokens
CREATE TABLE customers.refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES customers.accounts(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Mirror the same three tables under `providers` schema.

### admins schema

```sql
CREATE TABLE admins.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'superadmin')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE admins.refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES admins.accounts(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Seed one superadmin account on first run (read credentials from `appsettings.Development.json`).

---

## Backend Business Logic (step by step)

**Registration flow:**
1. Validate request (FluentValidation — phone format, password min 8 chars, name not empty)
2. Check phone not already registered → `409 Conflict` if taken
3. Hash password with BCrypt (cost factor 12)
4. Insert into `accounts` with `is_verified = false`
5. Generate 6-digit numeric OTP
6. Hash OTP with BCrypt, insert into `otp_verifications` with `expires_at = now() + 10 minutes`
7. Log OTP to console (stub) — structure the notification call so a real SMS provider can be wired in later
8. Return success message (never return the OTP)

**OTP verification flow:**
1. Look up account by phone
2. Look up latest `otp_verifications` record for the account
3. Check `expires_at > now()` → `400 "OTP expired"` if not
4. Check `attempts < 5` → `429 "Too many attempts"` if exceeded, increment attempt count on each failed check
5. Verify OTP with BCrypt.Verify()
6. On match: delete OTP record, set `is_verified = true`, issue JWT + refresh token
7. On mismatch: increment attempts, return `400 "Invalid OTP"`

**Login flow:**
1. Look up account by phone
2. If not found → `401 "INVALID_CREDENTIALS"` (don't leak whether phone exists)
3. If `is_verified = false` → `400 "EMAIL_NOT_VERIFIED"` (distinct error — frontend uses this to show resend link)
4. BCrypt.Verify(password, hash) → `401 "INVALID_CREDENTIALS"` if fails
5. Delete old refresh token if exists, issue new JWT + refresh token pair
6. Return tokens + user object

**JWT issuance (shared helper in `Khudmati.Shared`):**
- Claims: `sub` (user id), `aud` (audience), `role` (for admin), `iat`, `exp`
- Sign with HS256 using key from `appsettings.json` → `Jwt:Secret`
- Refresh token: generate `crypto-random` 64-byte string, store hash in DB, return plain value to client

---

## Flutter — Customer App Screens

### Screen: Splash / Route Guard
- Path: `lib/app/router.dart`
- On app start: check for stored access token → if valid, route to Home; if expired, attempt refresh; if no token, route to Welcome
- Use `SharedPreferences` to persist tokens locally

### Screen: Welcome (`lib/features/auth/presentation/welcome_screen.dart`)
- Purpose: Entry point for unauthenticated users
- UI: Khudmati logo, tagline in Arabic, two buttons — "أنا عميل" (I'm a Customer) + "أنا مزود خدمة" (I'm a Provider), small "تسجيل الدخول" (Login) link
- Brand: Full-screen brand blue background, amber CTA buttons
- RTL layout

### Screen: Register (`lib/features/auth/presentation/register_screen.dart`)
- Fields: Full name, phone number (with country code picker), email (optional), password, confirm password
- Validation inline (show error under each field as user types)
- On submit → call register API → navigate to OTP screen passing phone number
- Arabic labels, RTL form layout

### Screen: OTP Verification (`lib/features/auth/presentation/otp_screen.dart`)
- 6-digit OTP input (individual digit boxes, auto-advance on input)
- Show phone number at top: "أدخل الرمز المرسل إلى {phone}"
- 60-second countdown for "Resend OTP" button (disabled until countdown ends)
- Max 5 attempts shown as remaining tries
- On success → store tokens → navigate to Home
- On expired → show "انتهت صلاحية الرمز" with resend option

### Screen: Login (`lib/features/auth/presentation/login_screen.dart`)
- Fields: phone, password
- If API returns `EMAIL_NOT_VERIFIED` → show inline message "لم يتم التحقق من حسابك" with a "إعادة إرسال الرمز" (Resend OTP) link that navigates to OTP screen
- On success → store tokens → navigate to Home
- "نسيت كلمة المرور؟" (Forgot password) link — show "Coming soon" toast for v1

### Riverpod provider (`lib/features/auth/presentation/auth_provider.dart`)
- `AuthNotifier extends AsyncNotifier<AuthState>`
- States: `unauthenticated`, `loading`, `otpPending(phone)`, `authenticated(customer)`
- Methods: `register()`, `verifyOtp()`, `login()`, `logout()`, `refreshToken()`
- On `authenticated` → save tokens to SharedPreferences and update `GoRouter` redirect

### Repository (`lib/features/auth/data/auth_repository.dart`)
- All HTTP calls via `ApiClient` (Dio instance at `lib/core/api/api_client.dart`)
- On 401 from any request → attempt token refresh once → if refresh fails → emit `unauthenticated`

---

## Flutter — Provider App Screens

Mirror the same screens in `mobile-provider/lib/features/auth/` with:
- Welcome screen: "أنا مزود خدمة" as primary CTA
- Register screen: add "فئات الخدمة" (service categories) multi-select (checkboxes for: سباكة، كهرباء، تنظيف، نجارة، دهان — plumbing, electrical, cleaning, carpentry, painting)
- Same OTP, Login screens
- Auth provider audience = `provider`

---

## React — Admin Panel Auth

### Pages
- `web-admin/src/pages/Login/index.tsx` — email + password form, brand blue header with Khudmati logo
- On success → store token in `localStorage` under key `khudmati_admin_token` + role under `khudmati_admin_role`
- On fail → inline error message (do not use alert/toast for auth errors — show under the form)

### Route Guard
- `web-admin/src/router/ProtectedRoute.tsx` — already scaffolded; ensure it reads `khudmati_admin_token` and redirects to `/login` if missing or expired
- Add a `RoleGuard` component: if route requires `superadmin` and role is `admin` → redirect to `/403`

### Auth store (`web-admin/src/store/auth.store.ts`)
- Zustand store: `{ token, role, adminId, setAuth, clearAuth }`
- Hydrate from localStorage on app init

### Axios interceptor (already in `web-admin/src/api/client.ts`)
- Confirm the 401 interceptor calls `POST /api/auth/admin/refresh` once before redirecting to login
- If refresh succeeds → retry original request with new token
- If refresh fails → `clearAuth()` + redirect to `/login`

---

## Edge Cases & Validation

- Phone already registered → `409` with `"PHONE_ALREADY_REGISTERED"` — show "هذا الرقم مسجل مسبقاً" on register screen
- OTP expired → `400 "OTP_EXPIRED"` — show resend button immediately
- OTP wrong 5 times → `429 "MAX_ATTEMPTS_EXCEEDED"` — lock the OTP screen, show "يرجى طلب رمز جديد"
- Unverified login → `400 "EMAIL_NOT_VERIFIED"` — show resend OTP link, do NOT say "wrong password"
- Wrong password → `401 "INVALID_CREDENTIALS"` — show "رقم الهاتف أو كلمة المرور غير صحيحة"
- Refresh token expired → silently log out, redirect to login
- Network error → show "تحقق من اتصالك بالإنترنت" toast (Flutter) or inline message (React)

---

## Out of Scope (do not implement)
- Forgot password / password reset flow (v2)
- Social login (Google, Apple) — v2
- Biometric login — v2
- Admin self-registration — admins are seeded only
- Email-based OTP for providers (SMS only for providers in v1)
- Real SMS provider integration — use console log stub, leave interface ready

---

## Acceptance Criteria
- [ ] Customer can register with phone + password, receive OTP (logged to console), verify OTP, and receive JWT
- [ ] Customer can log in after verification and receive valid JWT with audience `customer`
- [ ] Unverified customer gets `EMAIL_NOT_VERIFIED` error on login, not a generic error
- [ ] OTP expires after 10 minutes and returns correct error
- [ ] After 5 wrong OTP attempts the endpoint returns 429
- [ ] Provider flow mirrors customer flow with `provider` audience JWT
- [ ] Admin can log in with email + password and receive JWT with audience `admin` or `superadmin`
- [ ] Refresh token rotates on each use (old token invalidated)
- [ ] Flutter app persists tokens and auto-refreshes on 401
- [ ] Admin panel redirects to `/login` if token missing or expired
- [ ] All Flutter screens render correctly in RTL Arabic layout
- [ ] No OTP value is ever returned in an API response
