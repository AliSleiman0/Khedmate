# Khudmati — Developer Onboarding

Everything a new developer needs to go from zero to a running stack.

---

## Prerequisites

Install these before anything else:

| Tool | Version | Notes |
|---|---|---|
| [.NET SDK](https://dotnet.microsoft.com/download) | 8.x | Backend |
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | Latest | Runs PostgreSQL locally |
| [Flutter](https://docs.flutter.dev/get-started/install) | 3.16+ | Both mobile apps |
| [Node.js](https://nodejs.org/) | 20+ | All three web apps |
| [Stripe CLI](https://stripe.com/docs/stripe-cli) | Latest | Local webhook forwarding |
| Android Studio / Xcode | Latest | Flutter emulators |

Verify everything is wired up:
```bash
dotnet --version      # 8.x.x
flutter doctor        # all green (Android toolchain required)
node --version        # v20.x.x
docker --version
stripe --version
```

---

## Local Development

### 1. Backend

```bash
cd backend

# Start PostgreSQL (local dev — port 5432)
docker-compose up -d postgres

# Copy secrets template
cp .env.example .env
```

Open `.env` and fill in the required values. The minimum to get running locally:

| Key | What to put |
|---|---|
| `POSTGRES_PASSWORD` | Any strong password |
| `JWT_KEY` | At least 32 random characters (`openssl rand -base64 48`) |
| `STRIPE_SECRET_KEY` | Your Stripe test secret key (`sk_test_...`) |
| `STRIPE_PUBLISHABLE_KEY` | Your Stripe test publishable key (`pk_test_...`) |
| `STRIPE_WEBHOOK_SECRET` | Filled in after you start the Stripe CLI (see below) |
| `FIREBASE_CREDENTIALS_JSON` | Service account JSON from Firebase Console (one line, escaped) |
| `SMTP2GO_API_KEY` | Your SMTP2Go API key (for OTP emails) |

You can skip `GROK_API_KEY` unless testing the AI feature.

```bash
# Run the API (from the backend/ directory)
cd src/Khudmati.API
dotnet run
```

API is live at `http://localhost:5000`. Swagger: `http://localhost:5000/swagger`.

> **OTPs go to the console.** There is no SMS provider wired up in dev — every OTP prints as a log line like `[OTP] 123456 for +966...`. Watch the terminal.

> **Skip Stripe for quick testing.** Set `PAYMENT_BYPASS=true` in `.env` to mark jobs as Paid immediately on completion without going through Stripe.

#### Manual SQL migrations

The EF Core migrations create the base schema on first run, but several features require additional SQL scripts that are not in EF migrations. After first `dotnet run` (once the schema exists), run all scripts in order:

```bash
# From psql or any Postgres client connected to khudmati (local dev)
# Run each file in order:
\i backend/add-disputes-table.sql
\i backend/add-superadmin-tables.sql
\i backend/add-photo-type-migration.sql
\i backend/add-referral-system.sql
\i backend/add-email-unique-index.sql
\i backend/add-subscription-plans.sql
\i backend/add-admin-features.sql
\i backend/add-subscription-screen.sql
\i backend/seed-skill-test-questions.sql
```

Or run them all at once via psql:
```bash
for f in add-disputes-table add-superadmin-tables add-photo-type-migration \
          add-referral-system add-email-unique-index add-subscription-plans \
          add-admin-features add-subscription-screen seed-skill-test-questions; do
  psql -h localhost -U khudmati_user -d khudmati -f "backend/$f.sql"
done
```

> **Critical**: `add-admin-features.sql` and `add-subscription-screen.sql` are required before the subscription and reminder-rules endpoints work. The API will throw on first request to those endpoints without them.

#### Stripe webhook forwarding (for payment testing)

```bash
stripe listen --forward-to localhost:5000/api/webhooks/stripe
```

The CLI will print a webhook signing secret (`whsec_...`). Paste it into `.env` as `STRIPE_WEBHOOK_SECRET`, then restart the API.

---

### 2. Flutter Apps (Customer + Provider)

Both apps follow the same setup:

```bash
cd mobile-customer   # or mobile-provider
flutter pub get
flutter run
```

**API base URL** is hardcoded per platform:
- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator: `http://localhost:5000/api`

Change it in `lib/core/api/api_client.dart` if needed.

**Stripe publishable key** is injected at build time via `--dart-define`. The debug default (`pk_test_REPLACE...`) works for emulator testing but must be set for any real device build:
```bash
flutter build apk --debug --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
```

---

### 3. Web Apps

All three web apps work the same way:

```bash
# web-landing (port 3000)
cd web-landing && npm install && npm run dev

# web-admin (port 3001)
cd web-admin && npm install && npm run dev

# web-superadmin (port 3002)
cd web-superadmin && npm install && npm run dev
```

Create a local `.env` file in each web directory pointing to your local backend:
```
VITE_API_URL=http://localhost:5000/api
```

> The committed `.env.production` files point to `https://khudmati.app/api` — do not use those locally.

**Default superadmin credentials** (seeded on first API startup):
- Email: `superadmin@khudmati.com`
- Password: `Admin@12345`

Use these to log into `http://localhost:3002` (superadmin) and create a regular admin account for `http://localhost:3001`.

---

## Feature Flags

| Flag | Default | How to enable locally |
|---|---|---|
| `Features:AiAssist` | `false` | Set `true` in `appsettings.Development.json` + add `Grok:ApiKey` |
| `Features:AiScheduling` | `false` | Set `true` in `appsettings.Development.json` |
| `PaymentBypass` | `false` | Set `PAYMENT_BYPASS=true` in `.env` — skips Stripe, marks job Paid immediately |

---

## Building Demo APKs (Windows)

There is a PowerShell script to build debug APKs for both apps at once:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\build-demo-apks.ps1
```

Prerequisites: Chocolatey, JDK 17, Android SDK or Android Studio.

Output: `Khudmati - Book a Service.apk` and `Khudmati - For Providers.apk` in the workspace root.

> Before sharing APKs with testers, update `AppConfig.backendHost` in `mobile-customer/lib/core/constants/app_config.dart` and `mobile-provider/lib/core/constants/app_config.dart` to point to the production server, then rebuild.

---

## Production

**Server**: DigitalOcean droplet at `157.230.22.154`
**App path on server**: `/opt/khudmati/backend/`
**Domain**: `api.khudmati.app` (API), `khudmati.app` (landing), `khudmati.app/admin`, `khudmati.app/superadmin`

### Fresh server setup (run once)

```bash
# SSH into the droplet as root, then:
bash backend/deploy/setup-droplet.sh
```

This installs Docker, configures UFW (ports 22/80/443), enables fail2ban, and creates `/opt/khudmati/`.

### First deploy

```bash
# Upload the backend/ folder to /opt/khudmati/backend/ via scp or git clone
scp -r backend/ root@157.230.22.154:/opt/khudmati/

# SSH in
ssh root@157.230.22.154
cd /opt/khudmati/backend

# Fill in production secrets
cp .env.example .env
nano .env   # fill all values with production keys

# Deploy
bash deploy/deploy.sh
```

### HTTPS (run once, after DNS is pointed)

```bash
# SSH into the droplet
bash /opt/khudmati/backend/deploy/setup-https.sh
```

Issues a Let's Encrypt cert for `khudmati.app`, `www.khudmati.app`, `api.khudmati.app` and installs a cron for auto-renewal.

### Ongoing backend deploys

```bash
ssh root@157.230.22.154
cd /opt/khudmati/backend
git pull                          # or re-upload changed files
bash deploy/deploy.sh             # rebuilds the API image + restarts services
```

### Web app deploys (landing, admin, superadmin)

The web apps are served as static files by nginx from `/var/www/{app}` on the server.

```bash
# Build locally (from each web directory)
VITE_API_URL=https://khudmati.app/api npm run build

# Upload dist/ to server
scp -r dist/ root@157.230.22.154:/var/www/landing/    # or admin / superadmin
```

### Post-deploy SQL migrations

When deploying a feature that includes new SQL scripts, run them on the production database before or immediately after deploying the backend:

```bash
# SSH into the droplet, then:
docker exec -i backend-postgres-1 psql -U khudmati_user -d khudmati < /opt/khudmati/backend/add-admin-features.sql
docker exec -i backend-postgres-1 psql -U khudmati_user -d khudmati < /opt/khudmati/backend/add-subscription-screen.sql
```

Check logs after deploy:
```bash
docker compose -f docker-compose.prod.yml logs -f api --tail=100
```

Health check:
```bash
curl https://api.khudmati.app/api/health
```

---

## Architecture Quick Reference

| Layer | Where | Notes |
|---|---|---|
| REST API + SignalR | `backend/` (.NET 8) | Port 5000 locally |
| Customer app | `mobile-customer/` (Flutter + Riverpod) | JWT audience: `customer` |
| Provider app | `mobile-provider/` (Flutter + Riverpod) | JWT audience: `provider` |
| Admin panel | `web-admin/` (React + Tailwind) | Port 3001, JWT audience: `admin` |
| Super admin | `web-superadmin/` (React + Tailwind) | Port 3002, JWT audience: `superadmin` |
| Landing page | `web-landing/` (React + i18next) | Port 3000, public |
| Database | PostgreSQL 16 | Schema-per-module |

For architecture details, see the `CLAUDE.md` file in each directory.
