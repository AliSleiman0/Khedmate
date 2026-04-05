# Task: Scaffold the Full Khudmati (خدمتي) Project Structure

## Project Overview
You are setting up **Khudmati (خدمتي)** — a two-sided home services marketplace for MENA markets.
The name means "My Service" in Arabic. This is a greenfield project. The folder is currently empty.

**Platforms to scaffold:**
- `backend/` — .NET 8 Web API (modular monolith)
- `mobile-customer/` — Flutter app for customers booking services
- `mobile-provider/` — Flutter app for service providers accepting jobs
- `web-landing/` — React + TypeScript public marketing/landing page
- `web-admin/` — React + TypeScript admin panel (operations team)
- `web-superadmin/` — React + TypeScript super admin panel (platform management)

---

## 1. Backend — .NET 8 Modular Monolith

**Path:** `backend/`

Create a clean architecture .NET 8 solution with the following structure:

```
backend/
├── Khudmati.sln
├── src/
│   ├── Khudmati.API/                          # Entry point — ASP.NET Core Web API
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   └── Controllers/                       # Thin controllers, delegate to modules
│   │
│   ├── Modules/
│   │   ├── Bookings/
│   │   │   ├── Khudmati.Modules.Bookings/
│   │   │   │   ├── Domain/
│   │   │   │   │   ├── Entities/Job.cs        # Job entity with status state machine
│   │   │   │   │   ├── Enums/JobStatus.cs     # Pending,Accepted,EnRoute,InProgress,Completed,Paid
│   │   │   │   │   └── Events/                # Domain events for state transitions
│   │   │   │   ├── Application/
│   │   │   │   │   ├── Commands/
│   │   │   │   │   ├── Queries/
│   │   │   │   │   └── DTOs/
│   │   │   │   ├── Infrastructure/
│   │   │   │   │   └── Persistence/
│   │   │   │   └── BookingsModule.cs          # Module registration/DI
│   │   │
│   │   ├── Customers/
│   │   │   └── Khudmati.Modules.Customers/
│   │   │       ├── Domain/Entities/Customer.cs
│   │   │       ├── Application/
│   │   │       ├── Infrastructure/
│   │   │       └── CustomersModule.cs
│   │   │
│   │   ├── Providers/
│   │   │   └── Khudmati.Modules.Providers/
│   │   │       ├── Domain/
│   │   │       │   ├── Entities/Provider.cs
│   │   │       │   └── Enums/VerificationTier.cs  # Unverified,IdVerified,SkillTested,PhoneVerified,Active
│   │   │       ├── Application/
│   │   │       ├── Infrastructure/
│   │   │       └── ProvidersModule.cs
│   │   │
│   │   ├── Payments/
│   │   │   └── Khudmati.Modules.Payments/
│   │   │       ├── Domain/Entities/Transaction.cs
│   │   │       ├── Application/
│   │   │       ├── Infrastructure/
│   │   │       └── PaymentsModule.cs
│   │   │
│   │   └── Notifications/
│   │       └── Khudmati.Modules.Notifications/
│   │           ├── Domain/Entities/Notification.cs
│   │           ├── Application/
│   │           ├── Infrastructure/
│   │           │   └── Hubs/JobHub.cs         # SignalR hub
│   │           └── NotificationsModule.cs
│   │
│   └── Khudmati.Shared/                       # Cross-cutting: base classes, result pattern, pagination
│       ├── Domain/
│       │   ├── BaseEntity.cs
│       │   └── AuditableEntity.cs
│       ├── Application/
│       │   └── Result.cs                      # Result<T> pattern for all responses
│       └── Infrastructure/
│           └── Persistence/AppDbContext.cs    # EF Core DbContext
│
├── tests/
│   ├── Khudmati.Modules.Bookings.Tests/
│   ├── Khudmati.Modules.Providers.Tests/
│   └── Khudmati.API.IntegrationTests/
│
└── docker-compose.yml                         # PostgreSQL + backend for local dev
```

**Key implementation details:**
- Use **EF Core 8** with PostgreSQL (Npgsql)
- Use **MediatR** for CQRS within each module
- Use **FluentValidation** for command/query validation
- Use **SignalR** hub in Notifications module (`/hubs/jobs`)
- `Job.cs` must implement a state machine — transitions are: `Pending → Accepted → EnRoute → InProgress → Completed → Paid`. Invalid transitions throw a domain exception and are logged as events.
- JWT authentication with **three separate token audiences**: `customer`, `provider`, `admin` — enforce audience validation per controller group
- All API responses use `Result<T>` wrapper: `{ success: bool, data: T, error: string }`
- Include a `docker-compose.yml` that spins up PostgreSQL on port 5432 with a `khudmati` database

---

## 2. Customer Mobile App — Flutter

**Path:** `mobile-customer/`

```
mobile-customer/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                  # MaterialApp with RTL + theme setup
│   │   ├── router.dart               # go_router route definitions
│   │   └── theme.dart                # Brand theme
│   ├── core/
│   │   ├── api/                      # Dio HTTP client, interceptors, token refresh
│   │   ├── constants/
│   │   │   ├── colors.dart           # brandBlue = 0xFF1B4F72, amber = 0xFFF39C12
│   │   │   └── strings.dart          # Arabic + English string keys
│   │   └── utils/
│   ├── features/
│   │   ├── auth/                     # Login, register, OTP verification
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── home/                     # Service category grid
│   │   ├── booking/                  # New booking flow: category → description → location → confirm
│   │   ├── tracking/                 # Live provider location map
│   │   ├── chat/                     # In-app SignalR chat
│   │   ├── history/                  # Past bookings
│   │   └── profile/                  # Account settings
│   └── shared/
│       ├── widgets/                  # Reusable UI components
│       └── providers/                # Riverpod providers
└── assets/
    ├── fonts/                        # Cairo + Inter font files
    └── images/
```

**Key implementation details:**
- Use **Riverpod** for state management
- Use **go_router** for navigation
- Use **Dio** for HTTP with an interceptor that attaches the JWT and handles 401 refresh
- Use **flutter_map** or **google_maps_flutter** for the tracking screen
- App must support **RTL (Arabic)** — set `textDirection: TextDirection.rtl` in MaterialApp and test all layouts in Arabic
- Brand colors: `brandBlue = Color(0xFF1B4F72)`, `amber = Color(0xFFF39C12)`
- Fonts: Cairo for Arabic text, Inter for English/numbers

---

## 3. Provider Mobile App — Flutter

**Path:** `mobile-provider/`

Same structure as `mobile-customer/` with provider-specific features:

```
lib/features/
├── auth/              # Provider login + onboarding (document upload, skill test)
├── jobs/              # Job list: new requests, active, history
├── job-detail/        # Accept/reject with 2-min countdown timer
├── navigation/        # En-route GPS navigation
├── earnings/          # Earnings summary, payout status
├── profile/           # Verification tier display, ratings
└── chat/              # In-app chat (same as customer side)
```

**Key difference from customer app:** The home screen is a job feed, not a booking flow. The most critical screen is `job-detail` — it must show a countdown timer (2 minutes) and prominent Accept / Reject buttons. Auto-reject on timeout.

---

## 4. Web Landing Page — React + TypeScript

**Path:** `web-landing/`

```
web-landing/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── assets/
    │   └── fonts/            # Cairo + Inter
    ├── styles/
    │   ├── globals.css        # CSS variables: --brand-blue: #1B4F72; --amber: #F39C12
    │   └── rtl.css            # RTL overrides
    ├── components/
    │   ├── layout/
    │   │   ├── Header.tsx     # Nav with language toggle (AR/EN) and Download App CTA
    │   │   └── Footer.tsx
    │   └── sections/
    │       ├── Hero.tsx       # Main headline + app store badges
    │       ├── HowItWorks.tsx # 3-step booking flow illustration
    │       ├── Services.tsx   # Service category grid
    │       ├── TrustBadges.tsx
    │       ├── ProviderCTA.tsx
    │       └── ContactForm.tsx
    └── i18n/
        ├── ar.json            # Arabic strings
        └── en.json            # English strings
```

**Key implementation details:**
- Use **Vite** as build tool
- Use **i18next** for AR/EN language toggle
- Arabic mode should flip to RTL (`dir="rtl"` on `<html>`)
- No heavy frameworks needed — plain React + CSS variables is fine for v1

---

## 5. Web Admin Panel — React + TypeScript

**Path:** `web-admin/`

```
web-admin/
├── package.json
├── vite.config.ts
├── tsconfig.json
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── api/                   # Axios instance with admin JWT
    ├── store/                 # Zustand stores
    ├── router/                # React Router v6 protected routes
    ├── layouts/
    │   └── AdminLayout.tsx    # Sidebar nav + topbar
    ├── pages/
    │   ├── Dashboard/         # KPI cards: jobs today, active providers, disputes open
    │   ├── Jobs/              # Jobs table with filters (status, date, provider)
    │   ├── Providers/         # Provider list + verification management
    │   ├── Customers/         # Customer list
    │   ├── Disputes/          # Dispute queue — 3-step mediation flow
    │   └── Settings/
    └── components/
        └── shared/            # Table, Modal, Badge, StatusChip components
```

**Key implementation details:**
- Use **Zustand** for state, **React Query** (TanStack Query) for server state
- Use **React Router v6** with protected routes (redirect to `/login` if no admin JWT)
- Use **Tailwind CSS** for styling — brand palette via tailwind.config
- Jobs table must show the full job status chip with colour coding: Pending=grey, Accepted=blue, EnRoute=yellow, InProgress=amber, Completed=green, Paid=teal
- Disputes page is the most important — must show evidence photos, chat log, and Accept/Reject refund buttons

---

## 6. Web Super Admin Panel — React + TypeScript

**Path:** `web-superadmin/`

Same structure as `web-admin/` with super-admin-level pages:

```
src/pages/
├── Dashboard/         # Platform-wide metrics
├── Organizations/     # Tenant/organisation management (future multi-region)
├── Admins/            # Create/manage admin users and their permissions
├── Financials/        # Commission ledger, payouts, float balance
├── Audit/             # Full audit log of all platform events
└── Config/            # Platform-wide config: commission rates, timeout windows, etc.
```

**Key difference from admin panel:** Super admin can create and manage admin accounts. It has access to financial ledgers and platform configuration. Use role guards — if JWT audience is not `superadmin`, redirect to 403.

---

## Root-Level Files

At the project root, also create:

```
.gitignore                  # Covers .NET, Flutter, Node, env files
README.md                   # Brief project overview and local dev setup instructions
```

---

## What to Generate

Scaffold all folders and files listed above. For each project:

1. Create the folder structure with placeholder files (real `Program.cs`, `pubspec.yaml`, `package.json`, etc. — not empty files)
2. Wire up the core dependencies (NuGet packages, Flutter pub packages, npm packages) with the correct versions
3. Add the brand colour constants and font config in each platform
4. For the backend, generate the `Job.cs` entity with the state machine and the `AppDbContext.cs` skeleton
5. Add a root `README.md` explaining how to run each platform locally

Do not implement business logic beyond what's listed above. The goal is a clean, well-structured scaffold that can be built into feature by feature.
