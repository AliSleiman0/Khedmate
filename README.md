# Khudmati (خدمتي)

> "My Service" — A two-sided home services marketplace for MENA markets.

**New to the project? Start here: [ONBOARDING.md](ONBOARDING.md)**

## Projects

| Project | Stack | Dev Port | Description |
|---|---|---|---|
| `backend/` | .NET 8 Modular Monolith | 5000 | REST API + SignalR |
| `mobile-customer/` | Flutter | — | Customer booking app |
| `mobile-provider/` | Flutter | — | Provider app with job dispatch |
| `web-landing/` | React + Vite | 3000 | Marketing site (bilingual AR/EN) |
| `web-admin/` | React + Vite + Tailwind | 3001 | Operations admin panel |
| `web-superadmin/` | React + Vite + Tailwind | 3002 | Platform super admin |

## Architecture

```
backend/
  src/
    Khudmati.API/               ← Entry point, JWT auth, Swagger, SignalR
    Khudmati.Shared/            ← BaseEntity, Result<T>, AppDbContext
    Modules/
      Bookings/                 ← Job entity (state machine), CQRS
      Customers/                ← Customer entity
      Providers/                ← Provider entity + VerificationTier enum
      Payments/                 ← Transaction entity
      Notifications/            ← Notification entity + SignalR JobHub
  tests/
    Khudmati.Modules.Bookings.Tests/
    Khudmati.Modules.Providers.Tests/
    Khudmati.API.IntegrationTests/
```

## Job Status Flow

```
Pending → Accepted → EnRoute → InProgress → Completed → Paid
```

## Local Development

### Prerequisites
- .NET 8 SDK
- Flutter 3.16+
- Node.js 20+
- Docker Desktop

### Backend
```bash
cd backend
docker-compose up -d          # Start PostgreSQL on :5432
cd src/Khudmati.API
dotnet run                    # API on :5000, Swagger at /swagger
```

### Flutter Apps
```bash
cd mobile-customer            # or mobile-provider
flutter pub get
flutter run
```

### Web Apps
```bash
cd web-landing                # or web-admin / web-superadmin
npm install
npm run dev
```

## Brand

| Token | Value | Usage |
|---|---|---|
| Primary Blue | `#1B4F72` | App bars, buttons, nav |
| Amber | `#F39C12` | CTAs, provider accent |
| Success | `#27AE60` | Completed states |
| Danger | `#E74C3C` | Errors, reject |
| Arabic Font | Cairo | All Arabic UI |
| Latin Font | Inter | Numbers, EN UI |

## Key Design Decisions

- **Modular Monolith**: modules are isolated by namespace — extractable to microservices later.
- **Job Timeout**: 2-minute countdown (configurable) before provider auto-rejects.
- **Commission**: 15% platform cut (configurable in Super Admin).
- **Tri-audience JWT**: `customer` | `provider` | `admin` — single issuer, separate audiences.
- **RTL-first**: Arabic is the primary locale; EN support via i18next.
