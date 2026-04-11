# Khudmati — Full Production Requirements

Everything needed to go from development to production: infrastructure, third-party accounts, environment variables, secrets, APK/web builds, and launch checklist.

---

## Table of Contents

1. [Third-Party Accounts & Keys to Obtain](#1-third-party-accounts--keys-to-obtain)
2. [Infrastructure](#2-infrastructure)
3. [Backend — Environment Variables & Secrets](#3-backend--environment-variables--secrets)
4. [Mobile Apps — APK / IPA Build Requirements](#4-mobile-apps--apk--ipa-build-requirements)
5. [Web Apps — Build & Deployment](#5-web-apps--build--deployment)
6. [Database Setup](#6-database-setup)
7. [Firebase Setup](#7-firebase-setup)
8. [Stripe Setup](#8-stripe-setup)
9. [Domain & TLS](#9-domain--tls)
10. [Security Hardening](#10-security-hardening)
11. [Monitoring & Alerting](#11-monitoring--alerting)
12. [Seed Data & First-Run Checklist](#12-seed-data--first-run-checklist)
13. [API Endpoint Reference](#13-api-endpoint-reference)

---

## 1. Third-Party Accounts & Keys to Obtain

### 1.1 Stripe
| Item | Where to get it | Used in |
|---|---|---|
| **Secret Key** (`sk_live_…`) | Stripe Dashboard → Developers → API keys | Backend `Stripe:SecretKey` |
| **Publishable Key** (`pk_live_…`) | Stripe Dashboard → Developers → API keys | Flutter apps `flutter_stripe` init |
| **Webhook Signing Secret** (`whsec_…`) | Stripe Dashboard → Developers → Webhooks → Add endpoint → Reveal | Backend `Stripe:WebhookSecret` |
| **Connect Account** | Stripe Dashboard → Connect → Get started | Required for provider payouts |
| **Subscription Price ID** (`price_…`) | Stripe Dashboard → Products → Create product "Power Provider" → Add price 99 SAR/month recurring | Backend DB `providers.subscription_plans.stripe_price_id` + Super Admin `/plans` page |

> **Webhook endpoint** to register in Stripe:
> `https://api.khudmati.com/api/stripe/webhook`
> Events to enable: `invoice.payment_succeeded`, `invoice.payment_failed`, `customer.subscription.deleted`, `payment_intent.succeeded`, `payment_intent.payment_failed`

### 1.2 Firebase
| Item | Where to get it | Used in |
|---|---|---|
| **Firebase Project** | [console.firebase.google.com](https://console.firebase.google.com) → Create project | — |
| **Android `google-services.json`** (customer) | Firebase Console → Project → Add Android app (`com.khudmati.customer`) → Download config | `mobile-customer/android/app/google-services.json` |
| **Android `google-services.json`** (provider) | Firebase Console → Add Android app (`com.khudmati.provider`) → Download config | `mobile-provider/android/app/google-services.json` |
| **iOS `GoogleService-Info.plist`** (customer) | Firebase Console → Add iOS app → Download | `mobile-customer/ios/Runner/GoogleService-Info.plist` |
| **iOS `GoogleService-Info.plist`** (provider) | Firebase Console → Add iOS app → Download | `mobile-provider/ios/Runner/GoogleService-Info.plist` |
| **Service Account JSON** | Firebase Console → Project Settings → Service accounts → Generate new private key | Backend `firebase-service-account.json` (or env var) |
| **FCM Server Key / Project ID** | Firebase Console → Project Settings → Cloud Messaging | Backend `Firebase:ProjectId` for push notifications |

### 1.3 Google Maps (Optional but recommended)
If you want native satellite/street tile layers instead of OpenStreetMap:
| Item | Where to get it | Used in |
|---|---|---|
| **Android Maps API Key** | Google Cloud Console → APIs & Services → Credentials | `mobile-customer/android/app/src/main/AndroidManifest.xml` |
| **iOS Maps API Key** | Google Cloud Console | `mobile-customer/ios/Runner/AppDelegate.swift` |

> The current stack uses `flutter_map` with OpenStreetMap tiles (free, no key needed). Google Maps is optional.

### 1.4 App Store Accounts
| Item | Platform | Notes |
|---|---|---|
| **Google Play Developer Account** | [play.google.com/console](https://play.google.com/console) | $25 one-time fee. Needed for both customer and provider APKs |
| **Apple Developer Program** | [developer.apple.com](https://developer.apple.com) | $99/year. Needed for iOS builds |

---

## 2. Infrastructure

### Minimum Production Setup

| Component | Recommended | Notes |
|---|---|---|
| **API Server** | 2 vCPU, 4 GB RAM | .NET 8 — can scale horizontally behind load balancer |
| **PostgreSQL** | Managed DB (AWS RDS / Supabase / Railway) | PostgreSQL 16, min 20 GB SSD |
| **File Storage** | AWS S3 or Azure Blob Storage | Job photos (before/after), provider ID documents |
| **CDN** | CloudFront / Cloudflare | Serve web builds + static assets |
| **SSL Certificate** | Let's Encrypt or ACM | Required for all domains |
| **SignalR — Redis Backplane** | Redis 7 | Required if API scales to >1 instance |

### Domains Required

| Domain | Target | Notes |
|---|---|---|
| `api.khudmati.com` | Backend API | Port 443, reverse proxy to :5000 |
| `khudmati.com` / `www.khudmati.com` | `web-landing` | Marketing site |
| `admin.khudmati.com` | `web-admin` | Operations team |
| `superadmin.khudmati.com` | `web-superadmin` | Platform owners only |
| `khudmati.app` | Deep links / universal links | Referral: `khudmati.app/join?ref=CODE` → mobile app |

### File Storage (for Job Photos & Documents)
The backend uploads photos (`POST /api/bookings/jobs/{id}/photos`). In production this must write to object storage, not local disk.

**Required configuration:**
```json
"Storage": {
  "Provider": "S3",
  "BucketName": "khudmati-uploads",
  "Region": "me-south-1",
  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  "BaseUrl": "https://khudmati-uploads.s3.me-south-1.amazonaws.com"
}
```
> If using Docker without S3, photos are stored under `/app/uploads` inside the container — volume-mount this path to persistent storage.

---

## 3. Backend — Environment Variables & Secrets

### 3.1 Full `appsettings.Production.json` Template

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=<DB_HOST>;Port=5432;Database=khudmati;Username=<DB_USER>;Password=<DB_PASS>;SSL Mode=Require"
  },
  "Jwt": {
    "Key": "<RANDOM_64_CHAR_SECRET>",
    "Issuer": "khudmati",
    "CustomerAudience": "customer",
    "ProviderAudience": "provider",
    "AdminAudience": "admin",
    "SuperAdminAudience": "superadmin"
  },
  "Stripe": {
    "SecretKey": "sk_live_<YOUR_LIVE_SECRET_KEY>",
    "PublishableKey": "pk_live_<YOUR_LIVE_PUBLISHABLE_KEY>",
    "WebhookSecret": "whsec_<YOUR_WEBHOOK_SIGNING_SECRET>",
    "Connect": {
      "RefreshUrl": "https://khudmati.com/stripe/reauth",
      "ReturnUrl": "https://khudmati.com/stripe/return"
    }
  },
  "Firebase": {
    "ServiceAccountPath": "",
    "CredentialsJson": "<INLINE_SERVICE_ACCOUNT_JSON_STRING>"
  },
  "CommissionRate": 0.15,
  "JobTimeoutMinutes": 2,
  "Features": {
    "AiScheduling": false
  },
  "SeedAdmin": {
    "Email": "superadmin@khudmati.com",
    "Password": "<STRONG_PASSWORD_CHANGE_IMMEDIATELY>"
  },
  "AllowedHosts": "api.khudmati.com",
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

### 3.2 Environment Variable Overrides (Docker / CI)

Prefer injecting secrets as environment variables rather than baking them into the image:

| Env Var | Maps to | Example |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | DB connection string | `Host=db;Port=5432;...` |
| `Jwt__Key` | JWT signing key (≥32 chars, random) | `openssl rand -base64 48` |
| `Stripe__SecretKey` | Stripe live secret key | `sk_live_…` |
| `Stripe__WebhookSecret` | Stripe webhook signing secret | `whsec_…` |
| `Firebase__CredentialsJson` | Firebase service account JSON (escaped) | `{"type":"service_account",...}` |
| `SeedAdmin__Email` | First superadmin email | `superadmin@khudmati.com` |
| `SeedAdmin__Password` | First superadmin password | Strong password |
| `ASPNETCORE_ENVIRONMENT` | Runtime environment | `Production` |
| `ASPNETCORE_URLS` | Listening address | `http://+:5000` |

### 3.3 JWT Key Requirements
- Minimum **32 characters** (256-bit for HMAC-SHA256)
- Recommended **64 characters** for production
- Generate: `openssl rand -base64 48` or use a secrets manager

---

## 4. Mobile Apps — APK / IPA Build Requirements

### 4.1 Pre-Build Steps (Both Apps)

#### Step 1 — Wire Firebase
Run `flutterfire configure` in each app directory to regenerate `firebase_options.dart` with real credentials:
```bash
# Install CLI
dart pub global activate flutterfire_cli

# Customer app
cd mobile-customer
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>

# Provider app
cd mobile-provider
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```
This rewrites:
- `mobile-customer/lib/firebase_options.dart`
- `mobile-provider/lib/firebase_options.dart`
- Places `google-services.json` into `android/app/`
- Places `GoogleService-Info.plist` into `ios/Runner/`

#### Step 2 — Point to Production API
Change the base URL in **both** apps from the emulator address to your production domain:

**`mobile-customer/lib/core/api/api_client.dart`**
```dart
// Change:
static const String baseUrl = 'http://10.0.2.2:5000/api';
// To:
static const String baseUrl = 'https://api.khudmati.com/api';
```

**`mobile-customer/lib/core/services/signalr_service.dart`**
```dart
// Change:
static const String hubUrl = 'http://10.0.2.2:5000/hubs/jobs';
// To:
static const String hubUrl = 'https://api.khudmati.com/hubs/jobs';
```

Do the same in `mobile-provider/lib/core/api/api_client.dart` and `mobile-provider/lib/core/services/signalr_service.dart`.

#### Step 3 — Android Signing Keystore
You need a keystore to sign the release APK/AAB:
```bash
keytool -genkey -v \
  -keystore khudmati-release.keystore \
  -alias khudmati \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Create `mobile-customer/android/key.properties`:
```properties
storePassword=<KEYSTORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=khudmati
storeFile=../khudmati-release.keystore
```

Do the same for `mobile-provider/android/key.properties`.

Update `mobile-customer/android/app/build.gradle` to load the keystore (standard Flutter release signing setup).

#### Step 4 — Stripe Publishable Key
Both the customer app **and provider app** initialise Stripe on startup. Replace the placeholder key in each:

**`mobile-customer/lib/main.dart`:**
```dart
// Change:
Stripe.publishableKey = 'pk_test_REPLACE_WITH_YOUR_TEST_KEY';
// To:
Stripe.publishableKey = 'pk_live_<YOUR_LIVE_PUBLISHABLE_KEY>';
```

**`mobile-provider/lib/main.dart`** (Feature #26 — subscription PaymentSheet):
```dart
// Change:
Stripe.publishableKey = const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: 'pk_test_REPLACE_WITH_YOUR_TEST_KEY');
// To:
Stripe.publishableKey = 'pk_live_<YOUR_LIVE_PUBLISHABLE_KEY>';
```

Alternatively, supply via `--dart-define` at build time:
```bash
flutter build apk --release --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_<YOUR_KEY>
```

### 4.2 Customer App Build

```bash
cd mobile-customer
flutter pub get
flutter build apk --release        # APK for direct distribution
flutter build appbundle --release  # AAB for Google Play Store
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

**Android permissions required** (verify in `android/app/src/main/AndroidManifest.xml`):
- `ACCESS_FINE_LOCATION` — GPS for booking location + live tracking
- `ACCESS_COARSE_LOCATION` — fallback location
- `INTERNET` — API + SignalR
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` — photo picker for booking
- `CAMERA` — optional camera capture
- `RECEIVE_BOOT_COMPLETED`, `VIBRATE` — FCM notifications

**App ID:** `com.khudmati.customer`

### 4.3 Provider App Build

```bash
cd mobile-provider
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

**Android permissions required:**
- `ACCESS_FINE_LOCATION` — GPS broadcast every 3s during EnRoute status
- `ACCESS_BACKGROUND_LOCATION` — location in background (Android 10+, requires special permission dialog)
- `INTERNET`
- `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` — ID document upload + after-photos
- `CAMERA` — document photo capture
- `RECEIVE_BOOT_COMPLETED`, `VIBRATE` — FCM notifications

**App ID:** `com.khudmati.provider`

### 4.4 iOS Build (Additional Requirements)

**Capabilities to enable in Xcode / Apple Developer Portal:**
- Push Notifications (APNs)
- Background Modes → Location updates (provider app only)
- Associated Domains → `applinks:khudmati.app` (for referral deep links)

**`Info.plist` keys required:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك لتحديد مكان الخدمة</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك أثناء تقديم الخدمة</string>
<key>NSCameraUsageDescription</key>
<string>لالتقاط صور الخدمة ووثائق الهوية</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>لاختيار صور الخدمة ووثائق الهوية</string>
```

**APNs Key:** Upload APNs authentication key (`.p8`) in Firebase Console → Project Settings → Cloud Messaging → iOS app configuration.

---

## 5. Web Apps — Build & Deployment

### 5.1 Environment Variables for Web Apps

#### `web-landing` — create `.env.production`
```env
VITE_API_BASE_URL=https://api.khudmati.com
```

#### `web-admin` — create `.env.production`
```env
VITE_API_BASE_URL=https://api.khudmati.com
```

#### `web-superadmin` — create `.env.production`
```env
VITE_API_BASE_URL=https://api.khudmati.com
```

> Update the Axios base URL in `src/api/client.ts` of both `web-admin` and `web-superadmin` to use `import.meta.env.VITE_API_BASE_URL` instead of a hardcoded `localhost` URL.

### 5.2 Build Commands

```bash
# Landing page
cd web-landing
npm install
npm run build     # outputs to dist/

# Admin panel
cd web-admin
npm install
npm run build     # outputs to dist/

# Super admin panel
cd web-superadmin
npm install
npm run build     # outputs to dist/
```

### 5.3 Deployment

Deploy each `dist/` folder as a static site. Recommended options:
- **Vercel / Netlify** — zero config, free tier available
- **AWS S3 + CloudFront** — cost-effective, global CDN
- **Nginx** on the same server as the API

**Nginx config example (SPA routing):**
```nginx
server {
    listen 443 ssl;
    server_name admin.khudmati.com;
    root /var/www/web-admin/dist;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 5.4 CORS — Backend Must Allow

Add these origins to the backend CORS policy in `Program.cs`:
```csharp
builder.Services.AddCors(options => {
    options.AddPolicy("Production", policy => {
        policy.WithOrigins(
            "https://khudmati.com",
            "https://www.khudmati.com",
            "https://admin.khudmati.com",
            "https://superadmin.khudmati.com"
        )
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials(); // Required for SignalR
    });
});
```

---

## 6. Database Setup

### 6.1 Production PostgreSQL Requirements
- PostgreSQL **16**
- Minimum 20 GB storage (scale based on photo volume)
- Daily automated backups
- Connection pooling (PgBouncer recommended for >20 concurrent connections)
- SSL required (`SSL Mode=Require` in connection string)

### 6.2 Schema Migrations

The project uses EF Core code-first migrations. Run them in order on the production database:

```bash
cd backend

# Apply all migrations (from the API project)
dotnet ef database update \
  --project src/Khudmati.API \
  --connection "Host=<PROD_HOST>;Database=khudmati;Username=<USER>;Password=<PASS>"
```

If running manually, the SQL migration files in the repo root can also be applied in order:
1. Base EF migration (runs automatically on startup via `context.Database.Migrate()`)
2. `add-disputes-table.sql`
3. `add-photo-type-migration.sql`
4. `add-referral-system.sql`
5. `add-superadmin-tables.sql`
6. `add-admin-features.sql` — creates `providers.provider_subscriptions` and `public.reminder_rules` (Features #18, #19)
7. `add-subscription-screen.sql` — adds `stripe_customer_id`, `cancels_at_period_end`, `cancelled_at` columns to `providers.provider_subscriptions` (Feature #26)

### 6.3 Performance Indexes (Run After Migration)

```sql
-- Analytics queries (Feature #20)
CREATE INDEX IF NOT EXISTS idx_transactions_provider_status_date
  ON payments.transactions(job_id, status, created_at);

CREATE INDEX IF NOT EXISTS idx_jobs_provider_status_date
  ON bookings.jobs(provider_id, status, created_at);

CREATE INDEX IF NOT EXISTS idx_ratings_provider_created
  ON bookings.ratings(provider_id, created_at DESC);

-- Reminders (Feature #19)
CREATE INDEX IF NOT EXISTS idx_scheduled_reminders_due
  ON public.scheduled_reminders(scheduled_for) WHERE status = 'Scheduled';

CREATE INDEX IF NOT EXISTS idx_scheduled_reminders_customer
  ON public.scheduled_reminders(customer_id);
```

### 6.4 Seed Data Required

The following must be seeded before the platform can function:

#### Reminder Rules (Feature #19)
```sql
INSERT INTO public.reminder_rules (id, category_id, category_name_ar, interval_days, is_active, created_at, updated_at)
VALUES
  (gen_random_uuid(), gen_random_uuid(), 'تكييف وتبريد', 90, true, NOW(), NOW()),
  (gen_random_uuid(), gen_random_uuid(), 'تنظيف عام', 30, true, NOW(), NOW()),
  (gen_random_uuid(), gen_random_uuid(), 'كهرباء', 365, true, NOW(), NOW()),
  (gen_random_uuid(), gen_random_uuid(), 'سباكة', 180, true, NOW(), NOW()),
  (gen_random_uuid(), gen_random_uuid(), 'نجارة', 365, true, NOW(), NOW());
```

#### Subscription Plan (Feature #18)
```sql
INSERT INTO providers.subscription_plans
  (id, name, monthly_fee, commission_rate, priority_delay_seconds, is_active, stripe_price_id, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'PowerProvider', 99.00, 10.00, 30, true, 'price_REPLACE_WITH_STRIPE_PRICE_ID', NOW(), NOW());
```

#### Skill Test Questions (Feature #07)
Run `backend/seed-skill-test-questions.sql` against the production database.

---

## 7. Firebase Setup

### 7.1 Enable Services in Firebase Console
1. **Cloud Messaging (FCM)** — required for push notifications (reminders, job alerts, dispute updates)
2. **Authentication** — NOT used for user auth (Khudmati uses its own OTP system), but Firebase project is still needed for FCM

### 7.2 Backend Firebase Configuration

Option A — File path (not recommended for production):
```json
"Firebase": {
  "ServiceAccountPath": "/secrets/firebase-service-account.json"
}
```

Option B — Inline JSON (recommended, via env var):
```bash
Firebase__CredentialsJson='{"type":"service_account","project_id":"...","private_key_id":"...","private_key":"-----BEGIN RSA PRIVATE KEY-----\n...","client_email":"...","client_id":"...",...}'
```

### 7.3 Push Notification Topics / Tokens
FCM device tokens are registered by the mobile apps on login. They are stored in the notifications system and used by:
- `ReminderDispatchWorker` — hourly background service that sends maintenance reminders
- Dispute notifications
- Verification status updates
- Subscription lifecycle events

---

## 8. Stripe Setup

### 8.1 Live Mode Checklist
- [ ] Stripe account activated (business verification complete)
- [ ] Live API keys generated (`sk_live_…`, `pk_live_…`)
- [ ] Stripe Connect enabled for platform (provider payouts)
- [ ] Webhook endpoint created: `https://api.khudmati.com/api/stripe/webhook`
- [ ] Webhook events subscribed: `invoice.payment_succeeded`, `invoice.payment_failed`, `customer.subscription.deleted`, `payment_intent.succeeded`, `payment_intent.payment_failed`
- [ ] Webhook signing secret copied to backend (`Stripe:WebhookSecret`)
- [ ] Product "Power Provider" created with recurring price 99 SAR/month
- [ ] Stripe Price ID pasted into DB `providers.subscription_plans.stripe_price_id`
- [ ] Payout schedule configured (daily/weekly to providers)

### 8.2 Stripe Connect — Provider Onboarding Flow
Providers complete Stripe Connect onboarding via:
```
GET /api/providers/earnings/stripe-onboarding-url
→ Redirects to Stripe Connect Express onboarding
→ Stripe redirects back to khudmati.com/stripe/return
```
The `Connect.ReturnUrl` and `Connect.RefreshUrl` in config must point to live domain URLs.

### 8.3 SAR Currency Note
Ensure Stripe account has **SAR (Saudi Arabian Riyal)** enabled. Stripe supports SAR for card payments and payouts. Minimum charge: 2 SAR.

---

## 9. Domain & TLS

### 9.1 DNS Records

| Record | Type | Value |
|---|---|---|
| `khudmati.com` | A | `<LANDING_SERVER_IP>` |
| `www.khudmati.com` | CNAME | `khudmati.com` |
| `api.khudmati.com` | A | `<API_SERVER_IP>` |
| `admin.khudmati.com` | A or CNAME | `<ADMIN_SERVER_IP_OR_CDN>` |
| `superadmin.khudmati.com` | A or CNAME | `<SUPERADMIN_SERVER_IP_OR_CDN>` |
| `khudmati.app` | A | `<DEEP_LINK_SERVER_OR_SAME>` |

### 9.2 Deep Links / Universal Links (Referral — Feature #17)

Referral deep link format: `khudmati.app/join?ref=CODE`

**Android — `assetlinks.json`**
Host at `https://khudmati.app/.well-known/assetlinks.json`:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.khudmati.customer",
    "sha256_cert_fingerprints": ["<YOUR_RELEASE_KEYSTORE_SHA256>"]
  }
}]
```
Get SHA-256 fingerprint:
```bash
keytool -list -v -keystore khudmati-release.keystore -alias khudmati
```

**iOS — `apple-app-site-association`**
Host at `https://khudmati.app/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAM_ID>.com.khudmati.customer",
      "paths": ["/join*", "/join?*"]
    }]
  }
}
```

### 9.3 TLS Certificate
Use Let's Encrypt (Certbot) or ACM (AWS):
```bash
certbot --nginx -d khudmati.com -d www.khudmati.com -d api.khudmati.com \
        -d admin.khudmati.com -d superadmin.khudmati.com -d khudmati.app
```

---

## 10. Security Hardening

### 10.1 Backend
- [ ] `AllowedHosts` set to `api.khudmati.com` (not `*`)
- [ ] JWT `Key` is a random 64-char secret (not the default placeholder)
- [ ] Swagger UI disabled in production: `if (!app.Environment.IsDevelopment()) { /* skip UseSwagger */ }`
- [ ] HTTPS redirection enforced: `app.UseHttpsRedirection()`
- [ ] HSTS enabled: `app.UseHsts()`
- [ ] Rate limiting on OTP endpoints (already in code as `MAX_ATTEMPTS_EXCEEDED`)
- [ ] Database user has minimal privileges (no `CREATE`, `DROP` in production runtime user)
- [ ] `SeedAdmin:Password` changed immediately after first login
- [ ] Stripe webhook signature verified on every webhook request (already in `StripeWebhookController`)
- [ ] Firebase credentials not committed to git (use env vars or secrets manager)

### 10.2 Mobile Apps
- [ ] TLS pinning (optional but recommended for production banking-grade apps)
- [ ] ProGuard / R8 minification enabled for Android release builds
- [ ] `android:debuggable="false"` in release manifest (set automatically by Flutter release build)
- [ ] API base URL points to HTTPS endpoint only
- [ ] Flutter Stripe SDK: publishable key is `pk_live_…` not `pk_test_…`

### 10.3 Web Apps
- [ ] API base URL uses HTTPS
- [ ] Content Security Policy headers on Nginx/CloudFront
- [ ] Admin and superadmin panels served only over HTTPS with HSTS
- [ ] No hardcoded credentials in frontend bundles

---

## 11. Monitoring & Alerting

### Recommended Stack
| Tool | Purpose | Free tier |
|---|---|---|
| **Sentry** | Exception tracking (backend + Flutter) | Yes |
| **Uptime Robot** | API uptime monitoring | Yes |
| **Grafana + Prometheus** | Metric dashboards | Self-hosted |
| **PgHero** | PostgreSQL query performance | Self-hosted |
| **Datadog / New Relic** | Full APM | Paid |

### Backend Health Endpoint
Expose a health check at `GET /health` (add `app.MapHealthChecks("/health")` in `Program.cs`) for uptime monitoring.

### Critical Alerts to Configure
- API response time > 2s
- Database connection failures
- Stripe webhook failures (Stripe Dashboard → Webhooks → Failure notifications)
- FCM send failures (Firebase Console → Messaging → Send error rates)
- Remaining available disk space < 20% (for photo uploads)
- Background job `ReminderDispatchWorker` failures

---

## 12. Seed Data & First-Run Checklist

### Order of Operations on First Deployment

```
1. Provision database (PostgreSQL 16)
2. Set all environment variables on the server
3. Deploy backend Docker image
4. Verify API starts and migrations run automatically
5. Run seed SQL scripts (reminder_rules, subscription_plans, skill_test_questions)
6. Register Stripe webhook in Stripe Dashboard
7. Create Power Provider product + price in Stripe → copy Price ID to DB
8. Log in to superadmin panel (superadmin@khudmati.com / seeded password)
9. Change superadmin password immediately
10. Create at least one admin account via superadmin panel
11. Configure platform settings in /config (commission rate, job timeout)
12. Deploy web apps (landing, admin, superadmin)
13. Build and distribute mobile APKs for internal testing
14. Run end-to-end test: register customer → book job → assign provider → complete → rate
15. Verify push notifications work (FCM)
16. Verify Stripe payment flow works with live keys
17. Submit APKs to Google Play / App Store
```

### Initial Super Admin Credentials (Change Immediately)
- Email: `superadmin@khudmati.com`
- Password: as set in `SeedAdmin:Password` env var

---

## 13. API Endpoint Reference

All endpoints exposed by the backend. Base URL: `https://api.khudmati.com`

### Public (No Auth)
| Method | Path | Feature |
|---|---|---|
| `GET` | `/api/landing/stats` | Platform stats for landing page |
| `POST` | `/api/landing/contact` | Contact form submission |

### Customer Auth
| Method | Path | Feature |
|---|---|---|
| `POST` | `/api/customers/auth/register` | Register new customer |
| `POST` | `/api/customers/auth/verify-otp` | Verify OTP → issue JWT |
| `POST` | `/api/customers/auth/login` | Login → request OTP |
| `POST` | `/api/customers/auth/refresh` | Refresh access token |

### Customer (Authenticated — audience: `customer`)
| Method | Path | Feature |
|---|---|---|
| `POST` | `/api/bookings/jobs` | Create job |
| `GET` | `/api/bookings/jobs/{id}` | Get job detail |
| `POST` | `/api/bookings/jobs/{id}/photos` | Upload before photos |
| `GET` | `/api/bookings/jobs/my` | Job history |
| `POST` | `/api/payments/create-intent` | Create Stripe PaymentIntent |
| `POST` | `/api/payments/confirm` | Confirm payment |
| `GET` | `/api/payments/my` | Transaction history |
| `POST` | `/api/bookings/ratings` | Rate a job (thumbs up/down + tags) |
| `POST` | `/api/bookings/disputes` | Raise a dispute |
| `GET` | `/api/customers/me/referral` | Get my referral code + stats |
| `POST` | `/api/customers/referral/apply` | Apply a referral code at signup |
| `GET` | `/api/customers/me/reminders` | Get my maintenance reminders |
| `PATCH` | `/api/customers/me/reminders/{id}` | Snooze / dismiss a reminder |

### Provider Auth
| Method | Path | Feature |
|---|---|---|
| `POST` | `/api/providers/auth/register` | Register new provider |
| `POST` | `/api/providers/auth/verify-otp` | Verify OTP → issue JWT |
| `POST` | `/api/providers/auth/login` | Login → request OTP |
| `POST` | `/api/providers/auth/refresh` | Refresh access token |

### Provider (Authenticated — audience: `provider`)
| Method | Path | Feature |
|---|---|---|
| `GET` | `/api/provider/jobs/available` | Available jobs feed |
| `POST` | `/api/provider/jobs/{id}/accept` | Accept a job |
| `POST` | `/api/provider/jobs/{id}/reject` | Reject a job |
| `POST` | `/api/provider/jobs/{id}/status` | Update job status (EnRoute → InProgress → Completed) |
| `POST` | `/api/provider/jobs/{id}/location` | Broadcast GPS location |
| `POST` | `/api/provider/jobs/{id}/after-photos` | Upload after-photos |
| `POST` | `/api/providers/onboarding/documents` | Submit ID documents |
| `GET` | `/api/providers/onboarding/status` | Get verification tier |
| `GET` | `/api/providers/onboarding/skill-test` | Get skill test questions |
| `POST` | `/api/providers/onboarding/skill-test` | Submit skill test answers |
| `GET` | `/api/providers/earnings` | Earnings summary |
| `GET` | `/api/providers/earnings/transactions` | Transaction list |
| `GET` | `/api/providers/earnings/stripe-onboarding-url` | Get Stripe Connect onboarding URL |
| `GET` | `/api/providers/me/subscription` | Get subscription info |
| `GET` | `/api/providers/me/subscription/setup-intent` | Create Stripe SetupIntent (returns `clientSecret`) |
| `POST` | `/api/providers/me/subscription` | Subscribe to Power Provider |
| `DELETE` | `/api/providers/me/subscription` | Cancel subscription (at period end) |
| `GET` | `/api/providers/me/analytics/earnings?period=` | Earnings analytics |
| `GET` | `/api/providers/me/analytics/jobs?period=` | Job stats analytics |
| `GET` | `/api/providers/me/analytics/ratings` | Rating analytics |

### Admin (audience: `admin`)
| Method | Path | Feature |
|---|---|---|
| `POST` | `/api/auth/admin/login` | Admin login |
| `POST` | `/api/auth/admin/refresh` | Refresh admin token |
| `GET` | `/api/admin/jobs` | Paginated job list with filters |
| `POST` | `/api/admin/jobs/{id}/cancel` | Force-cancel a job |
| `GET` | `/api/admin/disputes` | Disputes queue |
| `POST` | `/api/admin/disputes/{id}/resolve` | Resolve dispute (approve refund or reject) |
| `GET` | `/api/admin/providers` | Provider list with filters |
| `GET` | `/api/admin/providers/verification-queue` | Documents pending review |
| `POST` | `/api/admin/providers/{id}/verify-documents` | Approve or reject documents |
| `POST` | `/api/admin/providers/{id}/suspend` | Suspend a provider |
| `POST` | `/api/admin/providers/{id}/reinstate` | Reinstate a provider |
| `GET` | `/api/admin/subscriptions` | Subscription overview |
| `GET` | `/api/admin/reminder-rules` | List reminder rules |
| `PUT` | `/api/admin/reminder-rules/{id}` | Update reminder rule |

### Super Admin (audience: `superadmin`)
| Method | Path | Feature |
|---|---|---|
| `GET` | `/api/superadmin/dashboard` | Platform KPIs |
| `GET` | `/api/superadmin/admins` | Admin account list |
| `POST` | `/api/superadmin/admins` | Create admin account |
| `PUT` | `/api/superadmin/admins/{id}` | Update admin account |
| `DELETE` | `/api/superadmin/admins/{id}` | Revoke admin account |
| `GET` | `/api/superadmin/config` | Platform config |
| `PUT` | `/api/superadmin/config` | Update platform config |
| `GET` | `/api/superadmin/financials` | Financial ledger (date range) |
| `GET` | `/api/superadmin/audit` | Audit log |
| `GET` | `/api/superadmin/subscription-plans` | Subscription plan list |
| `PATCH` | `/api/superadmin/subscription-plans/{id}` | Update subscription plan |

### Stripe Webhook (No Auth — signature verified)
| Method | Path | Feature |
|---|---|---|
| `POST` | `/api/stripe/webhook` | Stripe event handler |

### SignalR Hub
| Hub URL | Groups joined by client |
|---|---|
| `wss://api.khudmati.com/hubs/jobs` | `providers-available`, `providers-power`, `customer-{id}`, `provider-{id}`, `job-{id}` |

---

*Last updated: April 2026 — covers Features #01 through #26*
