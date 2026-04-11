# Backend — .NET 8 Modular Monolith

## New tables (Feature #15)
- `admins.platform_config` — single-row platform settings (commission rate, job timeout, max providers per area, etc.)
- `admins.audit_log` — immutable log of all super admin actions with `admin_id`, `action_type`, `description`, `target_type`, `target_id`

Migration: `AddSuperAdminTables`

## New tables (Feature #16)
- `public.contact_inquiries` — landing page contact form submissions (`id`, `name`, `email`, `message`, `submitted_at`)

EF entity: `Khudmati.API/Domain/ContactInquiry.cs`
Migration: `AddContactInquiriesTable`

## New tables (Feature #17)
- `customers.referral_codes` — one unique 8-char uppercase alphanumeric code per customer (`id`, `customer_id`, `code VARCHAR(10) UNIQUE`, `created_at`); unique index on `customer_id`
- `customers.referral_uses` — referrer↔referee link with status `Pending → Completed` (`id`, `referrer_customer_id`, `referred_customer_id`, `qualifying_booking_id`, `referrer_credit_amount`, `referee_discount_pct`, `status`, `created_at`, `completed_at`); unique index on `referred_customer_id`
- `customers.customer_credits` — platform credit wallet (`id`, `customer_id`, `amount`, `source_type VARCHAR(30)` — `Referral|Promo|Refund`, `source_id`, `expires_at`, `created_at`, `used_at`)

EF entities: `Modules/Customers/Domain/ReferralCode.cs`, `ReferralUse.cs`, `CustomerCredit.cs`
New endpoints: `GET /api/customers/me/referral`, `POST /api/customers/referral/apply`
Event handler: `Khudmati.API/EventHandlers/ReferralAwardHandler.cs` — listens to `JobStatusChangedEvent(Paid)`, awards referrer credit on first qualifying booking

## New tables (Feature #18)
- `providers.subscription_plans` — admin-managed plan config (`id`, `name VARCHAR(50)`, `monthly_fee NUMERIC(10,2)`, `commission_rate NUMERIC(5,2)`, `priority_delay_seconds INT DEFAULT 30`, `is_active BOOLEAN`, `stripe_price_id VARCHAR(100)`, `created_at`, `updated_at`); seeded with one `PowerProvider` row (99.00, 10.00, 30 s)
- `providers.provider_subscriptions` — per-provider subscription state (`id`, `provider_id`, `plan_id`, `stripe_subscription_id VARCHAR(100) UNIQUE`, `stripe_customer_id VARCHAR(100)`, `status VARCHAR(20)` — `Active|PastDue|Cancelled|Paused`, `current_period_start`, `current_period_end`, `cancelled_at`, `created_at`, `updated_at`); unique partial index on `provider_id WHERE status IN ('Active','PastDue')` enforces one active sub per provider
- `payments.transactions` — added column `commission_rate_applied NUMERIC(5,2)` to store the rate used at payout time

EF entities: `Modules/Providers/Domain/SubscriptionPlan.cs`, `ProviderSubscription.cs`
New commands: `SubscribePowerProviderCommand`, `CancelSubscriptionCommand`
New query: `GetSubscriptionInfoQuery`
Webhook handler: `Khudmati.API/Controllers/StripeWebhookController.cs` — handles `invoice.payment_succeeded`, `invoice.payment_failed`, `customer.subscription.deleted`
Priority broadcast: `providers-power` SignalR group receives `NewJobAvailable` 30 s before `providers-available`; uses `Task.Run` + `Task.Delay` + status re-check before second broadcast
Commission resolution: at payout, check for Active `provider_subscriptions` row → use `subscription_plans.commission_rate`; fallback to platform default (15%)
Grace period: PastDue providers retain Power Provider benefits for 3 days before status reverts to Standard

## New tables (Feature #19)
- `public.reminder_rules` — admin-managed reminder interval per category (`id`, `category_id UUID`, `category_name_ar VARCHAR(100)`, `interval_days INT`, `is_active BOOLEAN`, `created_at`, `updated_at`); seeded with rules for AC (90d), General Cleaning (30d), Electrical (365d), Plumbing (180d), Carpentry (365d)
- `public.scheduled_reminders` — per-customer reminder lifecycle (`id`, `customer_id`, `job_id`, `category_id`, `category_name_ar`, `scheduled_for TIMESTAMPTZ`, `status VARCHAR(20)` — `Scheduled|Sent|Dismissed|Snoozed|Booked`, `snoozed_until`, `sent_at`, `dismissed_at`, `created_at`, `updated_at`); indexes on `(scheduled_for) WHERE status='Scheduled'` and `(customer_id)`

EF entities: `Modules/Customers/Domain/ReminderRule.cs`, `ScheduledReminder.cs`
New commands: `UpdateReminderStatusCommand` (Dismiss | Snooze | MarkBooked)
New query: `GetMyRemindersQuery` — returns Scheduled/Sent/Snoozed reminders for customer
Event handler: `Khudmati.API/EventHandlers/MaintenanceReminderHandler.cs` — listens to `JobStatusChangedEvent(Paid)`, calls `IRemindersScheduler`, inserts `ScheduledReminder`
Background worker: `Khudmati.API/Infrastructure/BackgroundServices/ReminderDispatchWorker.cs` — `PeriodicTimer` (1h), queries due reminders, sends push notifications, sets status=Sent
Scheduler interface: `Modules/Customers/Application/Services/IRemindersScheduler.cs`; V1 impl: `RuleBasedRemindersScheduler`; stub: `AiRemindersScheduler`; toggled by `Features:AiScheduling` appsettings flag
New admin endpoints: `GET /api/admin/reminder-rules`, `PUT /api/admin/reminder-rules/{id}`
New customer endpoints: `GET /api/customers/me/reminders`, `PATCH /api/customers/me/reminders/{id}`
Duplicate suppression: skip scheduling if customer was reminded for same category within last 14 days

## New controllers (Feature #26)
Provider-facing subscription and analytics controllers added to `Khudmati.API/Controllers/Providers/`:
- `ProviderSubscriptionController.cs` — GET / GET setup-intent / POST / DELETE on `api/providers/me/subscription`; creates Stripe Customer on first call, stores `StripeCustomerId` on entity; fires SignalR events to `provider-{userId}` group
- `ProviderAnalyticsController.cs` — GET earnings / jobs / ratings on `api/providers/me/analytics/*`; all set `Cache-Control: max-age=300`; never return 404 (zero-safe)

Entity extended: `ProviderSubscription` gains `StripeCustomerId`, `CancelsAtPeriodEnd`, `CancelledAt`, `Create()`, `SetStatus()`, `SetCancelsAtPeriodEnd()`, `UpdatePeriod()` methods.

## New queries (Feature #20)
Analytics endpoints — no new DB tables; queries aggregate existing data:
- `GET /api/providers/me/analytics/earnings?period=` — aggregates `payments.transactions` (status=Released) by day/week/month; returns `currentPeriodEarnings`, `previousPeriodEarnings`, `changePercent` (nullable), `pendingEarnings` (Held txns), `chartDataPoints`
- `GET /api/providers/me/analytics/jobs?period=` — aggregates `bookings.jobs` by status; returns `completedJobs`, `rejectedJobs`, `expiredJobs`, `acceptanceRate`, `avgJobValueNet`, `topCategories` (top 5 by count)
- `GET /api/providers/me/analytics/ratings` — reads `providers.rating_stats` + `bookings.ratings`; returns `positiveRatePct` (nullable when totalRatings=0), `totalRatings`, `topPositiveTags`, `topNegativeTags`, `recentRatings` (last 10 for sparkline)
Never return 404 — return zero/null-safe response even for providers with no data
`changePercent` and `positiveRatePct` are nullable (null when previous period = 0 or no ratings)
Period enum: `Last7Days | Last30Days | Last3Months | AllTime`; truncation unit: day/week/month
Add `Cache-Control: max-age=300` response headers on all three analytics endpoints

Performance indexes added:
```sql
CREATE INDEX idx_transactions_provider_status_date ON payments.transactions(job_id, status, created_at);
CREATE INDEX idx_jobs_provider_status_date ON bookings.jobs(provider_id, status, created_at);
CREATE INDEX idx_ratings_provider_created ON bookings.ratings(provider_id, created_at DESC);
```

## Admin panel wiring (web-admin complete API integration)
New controllers added to `Khudmati.API/Controllers/` — all `[Authorize(Policy = "AdminOnly")]`:

| Controller | Endpoints | Notes |
|---|---|---|
| `AdminDashboardController` | `GET /api/admin/dashboard` | Live KPIs: totalJobs, pendingJobs, activeJobs, openDisputes, pendingVerifications, todayRevenue, recentJobs (last 5) |
| `AdminDashboardController` | `GET /api/admin/platform-config` | Read-only view of `admins.platform_config` for admin role |
| `AdminSubscriptionsController` | `GET /api/admin/subscriptions` | Joins provider_subscriptions + providers + subscription_plans; search/status/pagination |
| `AdminReminderRulesController` | `GET/POST /api/admin/reminder-rules` | List all rules; create new rule (blocks duplicate category) |
| `AdminReminderRulesController` | `PUT /api/admin/reminder-rules/{id}` | Update intervalDays + isActive |

New domain classes (API-local, not in modules):
- `Khudmati.API/Domain/ProviderSubscription.cs` — maps to `providers.provider_subscriptions`
- `Khudmati.API/Domain/ReminderRule.cs` — maps to `public.reminder_rules`

### ⚠️ Before deploying
Run these SQL scripts against PostgreSQL **in order** before deploying the backend:

1. `backend/add-admin-features.sql` — creates:
   - `providers.provider_subscriptions` table (needed by `AdminSubscriptionsController`)
   - `public.reminder_rules` table (needed by `AdminReminderRulesController`)

2. `backend/add-subscription-screen.sql` (Feature #26) — adds columns to `providers.provider_subscriptions`:
   - `stripe_customer_id VARCHAR(100)` — Stripe Customer object ID for reusing SetupIntents
   - `cancels_at_period_end BOOLEAN NOT NULL DEFAULT FALSE` — tracks scheduled cancellation
   - `cancelled_at TIMESTAMPTZ` — when the provider initiated cancellation

Without migration #1 the subscription and reminder-rules endpoints will throw on first request.
Without migration #2 the provider-facing `ProviderSubscriptionController` will fail to read/write subscription state.

## Grok AI — Job Description Helper (Feature #21)
New files — no DB migration required:
- `Khudmati.API/Controllers/AiController.cs` — `POST /api/ai/improve-description` (CustomerOnly auth). Returns `503` if `Features:AiAssist = false`, `502` if Grok API fails.
- `Khudmati.API/Services/IGrokService.cs` — interface `ImproveDescriptionAsync(roughDescription, categoryName)`
- `Khudmati.API/Services/GrokService.cs` — calls Grok API (`https://api.x.ai/v1/chat/completions`) using `IHttpClientFactory("grok")`, model `grok-3-mini`, max_tokens 400, temperature 0.4. Returns null on failure (logged).
- Request DTO: `{ roughDescription (max 500 chars), categoryName }` → Response: `{ improvedDescription }`
- **Feature flag**: `Features:AiAssist` in appsettings (default `false`). Enable locally in `appsettings.Development.json`.
- **API key**: `Grok:ApiKey` in appsettings/env. Never committed. Stored in server `.env` as `GROK_API_KEY`.
- **Dev testing**: `appsettings.Development.json` sets `Features:AiAssist: true` and `Grok:ApiKey: xai-...`

## Run
```bash
# Start Postgres (local dev)
docker-compose up -d postgres

# Run API (from backend/)
dotnet run --project src/Khudmati.API

# Run tests
dotnet test
```
API is available at `http://localhost:5000`. Swagger at `http://localhost:5000/swagger`.

## Production deployment (server: 157.230.22.154)
Always use `docker-compose.prod.yml` on the server — it reads credentials from `.env`:
```bash
# On server: /opt/khudmati/backend/
docker compose -f docker-compose.prod.yml build api
docker compose -f docker-compose.prod.yml up -d api
```
`docker-compose.yml` has been renamed to `docker-compose.dev.yml` on the server to prevent accidental use.

**Production `.env` keys** (server only — `/opt/khudmati/backend/.env`):
- `POSTGRES_USER=khudmati_user`, `POSTGRES_PASSWORD=SomethingStrong123!`
- `JWT_KEY`, `STRIPE_*`, `GROK_API_KEY`, `AI_ASSIST_ENABLED=true`

## Known bugs fixed
- `SuperAdminController.GetDashboard` — EF Core could not translate `.Status.ToString()` inside a LINQ `.CountAsync()`. Fixed by comparing `JobStatus` enum values directly instead of converting to string.

## Solution structure
```
backend/
├── src/
│   ├── Khudmati.API/           # Entry point — thin controllers, DI wiring, Program.cs
│   ├── Khudmati.Shared/        # Cross-cutting: BaseEntity, Result<T>, JwtService, AppDbContext
│   └── Modules/
│       ├── Bookings/           # Job state machine (Pending→Accepted→EnRoute→InProgress→Completed→Paid)
│       ├── Customers/          # Customer registration, OTP auth, JWT issuance
│       ├── Providers/          # Provider registration, OTP auth, service categories, location, onboarding, verification
│       ├── Payments/           # Transaction entity, 20% commission, Stripe PaymentSheet + Connect payouts, 24h hold
│       └── Notifications/      # Notification entity + SignalR JobHub at /hubs/jobs
└── tests/
```

## Architecture rules
- **Thin controllers**: controllers only map HTTP ↔ MediatR commands/queries. No business logic.
- **CQRS via MediatR**: commands mutate state, queries read state. Both live in `Application/`.
- **FluentValidation pipeline**: `ValidationBehavior<,>` runs validators before every command handler.
- **Result<T> pattern**: handlers return `Result<T>` (never throw for business errors). Controllers map errors to HTTP codes.
- **No cross-module imports**: modules only share through `Khudmati.Shared` or domain events.

## CRITICAL — AppDbContext / EF Core pattern
`Khudmati.Shared` has **no project references to any module**. `AppDbContext` contains only:
```csharp
public static Action<ModelBuilder>? AdditionalModelConfiguration { get; set; }
protected override void OnModelCreating(ModelBuilder b) => AdditionalModelConfiguration?.Invoke(b);
```
All entity configurations (schemas, indexes, relationships, sequences) are set in **`Program.cs`** (API project) via:
```csharp
AppDbContext.AdditionalModelConfiguration = builder => { /* all Fluent API here */ };
```
The API project references all modules, so no circular deps.

**Repositories never use DbSet properties** — always use `_context.Set<T>()`.

## Auth design
| Audience | User type | Access token | Refresh token |
|---|---|---|---|
| `customer` | Mobile customer | 15 min | 30 days |
| `provider` | Mobile provider | 15 min | 30 days |
| `admin` | Web admin panel | 60 min | 8 hours |
| `superadmin` | Web superadmin panel | 60 min | 8 hours |

Refresh token format issued to clients: `"{tokenId}:{base64urlRandomBytes}"`
On verify: split on `:`, look up by `tokenId` (PK), BCrypt verify the random part.
One active refresh token per user — issuing a new one deletes the old one.

Authorization policies registered in Program.cs:
- `CustomerOnly` — requires JWT audience `customer`
- `ProviderOnly` — requires JWT audience `provider`
- `AdminOnly` — requires JWT audience `admin`
- `SuperAdminOnly` — requires JWT audience `superadmin`

## Error code → HTTP status
| Error code | Status |
|---|---|
| `PHONE_ALREADY_REGISTERED` | 409 |
| `INVALID_CREDENTIALS` | 401 |
| `EMAIL_NOT_VERIFIED` | 400 |
| `OTP_EXPIRED` | 400 |
| `INVALID_OTP` | 400 |
| `MAX_ATTEMPTS_EXCEEDED` | 429 |
| `RATE_LIMIT_EXCEEDED` | 429 |
| `INVALID_REFRESH_TOKEN` | 401 |
| `JOB_NOT_FOUND` | 404 |
| `JOB_NO_LONGER_AVAILABLE` | 410 |
| `PROVIDER_NOT_VERIFIED` | 403 |
| `PAYMENT_ALREADY_EXISTS` | 409 |
| `TRANSACTION_NOT_FOUND` | 404 |
| `PROVIDER_STRIPE_ACCOUNT_NOT_FOUND` | 404 |
| `PAYMENT_RELEASE_FAILED` | 500 |
| `JOB_NOT_ELIGIBLE_FOR_RATING` | 400 |
| `RATING_WINDOW_EXPIRED` | 400 |
| `ALREADY_RATED` | 409 |
| `SUBMISSION_ALREADY_PENDING` | 409 |
| `FILE_TOO_LARGE` | 400 |
| `UNSUPPORTED_FILE_TYPE` | 400 |
| `TEST_COOLDOWN_ACTIVE` | 429 |
| `INSUFFICIENT_QUESTIONS` | 400 |
| `TEST_SESSION_NOT_FOUND` | 404 |
| `TEST_SESSION_EXPIRED` | 400 |
| `REJECTION_REASON_REQUIRED` | 400 |
| `TRACKING_NOT_ACTIVE` | 400 |
| `INVALID_COORDINATES` | 400 |
| `AFTER_PHOTO_REQUIRED` | 422 |
| `INVALID_JOB_STATUS` | 400 |
| `CANNOT_CANCEL_JOB_IN_CURRENT_STATUS` | 422 |
| `DISPUTE_WINDOW_CLOSED` | 422 |
| `DISPUTE_ALREADY_EXISTS` | 422 |
| `STRIPE_REFUND_FAILED` | 502 |
| `PROVIDER_ALREADY_SUSPENDED` | 409 |
| `PROVIDER_NOT_SUSPENDED` | 409 |
| `VALIDATION_ERROR` | 400 |
| `REFERRAL_NOT_FOUND` | 404 |
| `REFERRAL_ALREADY_USED` | 409 |
| `REFERRAL_SELF_REFERRAL` | 422 |
| `PROVIDER_NOT_ACTIVE` | 403 |
| `ALREADY_SUBSCRIBED` | 409 |
| `PAYMENT_METHOD_INVALID` | 422 |
| `STRIPE_ERROR` | 502 |
| `CUSTOMER_NOT_FOUND` | 404 |
| `CUSTOMER_ALREADY_INACTIVE` | 400 |

## OTP flow
1. Register → 6-digit OTP generated, BCrypt-hashed, stored in `*.otp_verifications` with 10-min expiry
2. OTP logged to console by `ConsoleOtpNotificationService` (swap with real SMS provider via `IOtpNotificationService`)
3. Max 5 verify attempts before `MAX_ATTEMPTS_EXCEEDED`
4. Max 3 resend attempts per phone per 10 minutes

## API endpoints

### Customers — `/api/customers/`
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `auth/register` | None | Register + send OTP |
| POST | `auth/verify-otp` | None | Verify OTP → JWT |
| POST | `auth/resend-otp` | None | Resend OTP |
| POST | `auth/login` | None | Login → JWT |
| POST | `auth/refresh` | None | Refresh access token |

### Admin Customer Management — `/api/customers/` (AdminOnly)
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/api/customers` | AdminOnly | Paginated customer list (query: `search`, `isActive`, `page`, `pageSize=20`) → `{ customers, total, page, pageSize }` |
| GET | `/api/customers/{id}` | AdminOnly | Get customer by ID → `CustomerDto`; 404 on `CUSTOMER_NOT_FOUND` |
| PATCH | `/api/customers/{id}/deactivate` | AdminOnly | Deactivate customer account (sets `IsActive = false`); 404 on `CUSTOMER_NOT_FOUND`, 400 on `CUSTOMER_ALREADY_INACTIVE` |

MediatR handlers: `GetAllCustomersQuery`, `GetCustomerByIdQuery`, `DeactivateCustomerCommand`  
All live in `Modules/Customers/Khudmati.Modules.Customers/Application/`

### Bookings — `/api/bookings/` (CustomerOnly)
| Method | Route | Description |
|---|---|---|
| POST | `jobs` | Create job (JSON) |
| POST | `jobs/{jobId}/photos` | Upload photos (multipart) |
| GET | `jobs/{jobId}` | Get job detail (includes `hasOpenDispute: bool`) |
| GET | `jobs` | List customer's own jobs |
| POST | `jobs/{jobId}/dispute` | Open a dispute (job must be Paid, transaction must be Held) |

### Ratings — `/api/ratings/`
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/api/ratings` | CustomerOrProvider | Submit thumbs up/down + optional tags |
| GET | `/api/ratings/pending` | CustomerOrProvider | Jobs within 48h window with no rating yet |
| GET | `/api/providers/{id}/rating` | Public | Provider aggregate rating stats |

### Provider Jobs — `/api/provider/jobs/` (ProviderOnly)
| Method | Route | Description |
|---|---|---|
| GET | `available` | List jobs within 10km |
| GET | `{jobId}` | Get job detail (410 if expired) |
| POST | `{jobId}/respond` | Accept or reject job |
| PUT | `location` | Upsert provider GPS location |
| GET | `active` | List accepted jobs for provider |
| POST | `{jobId}/after-photos` | Upload after-photos (multipart, 1–5 images, job must be InProgress) |

### Tracking — `/api/tracking/` (ProviderOnly)
| Method | Route | Description |
|---|---|---|
| POST | `jobs/{jobId}/location` | Send live GPS location during EnRoute status |

### Providers — `/api/providers/`
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `auth/register` | None | Register + send OTP |
| POST | `auth/verify-otp` | None | Verify OTP → JWT |
| POST | `auth/resend-otp` | None | Resend OTP |
| POST | `auth/login` | None | Login → JWT |
| POST | `auth/refresh` | None | Refresh access token |
| GET | `{id:guid}` | Authorize | Public provider profile (id, fullName, phone, tier, serviceCategories, rating, jobsCompleted, createdAt); 404 on `PROVIDER_NOT_FOUND` |
| PATCH | `me` | ProviderOnly | Update own profile (`{ fullName }`) — 400 on `INVALID_FULL_NAME`; calls `provider.UpdateFullName()` then saves |
| GET | `earnings/summary` | ProviderOnly | Pending/available balance + Stripe Connect status |
| POST | `stripe/onboard` | ProviderOnly | Generate Stripe Connect Express onboarding URL |
| GET | `onboarding/status` | ProviderOnly | Get provider onboarding/verification status |
| POST | `onboarding/documents` | ProviderOnly | Submit ID documents (multipart/form-data) |
| GET | `onboarding/skill-test/{categoryId}` | ProviderOnly | Start skill test (10 questions) |
| POST | `onboarding/skill-test/{categoryId}/submit` | ProviderOnly | Submit skill test answers |
| GET | `me/jobs?status=Paid&page=1&pageSize=20` | ProviderOnly | Provider's completed/paid jobs; left-joins `payments.transactions` for netAmount; returns items+total+hasNextPage |

### Payments — `/api/payments/`
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `intent` | CustomerOnly | Create Stripe PaymentIntent → returns clientSecret |
| POST | `confirm` | CustomerOnly | Link PaymentIntent to job after PaymentSheet completes |
| GET | `my-transactions` | CustomerOrProvider | Paged transaction history (routed by JWT `aud`) |

### Provider Subscription — `/api/providers/me/subscription` (Feature #26 — `ProviderSubscriptionController.cs`)
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `me/subscription` | ProviderOnly | Current subscription state (null/404 if not subscribed) |
| GET | `me/subscription/setup-intent` | ProviderOnly | Create (or reuse) Stripe Customer + SetupIntent → returns `{ clientSecret }` for PaymentSheet |
| POST | `me/subscription` | ProviderOnly | Subscribe to Power Provider — resolves PaymentMethod from SetupIntent, creates Stripe Subscription, fires `SubscriptionActivated` SignalR |
| DELETE | `me/subscription` | ProviderOnly | Cancel at period end — sets `CancelAtPeriodEnd=true` on Stripe, fires `SubscriptionCancelled` SignalR |

### Stripe Webhooks — `/api/webhooks/stripe`
| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/api/webhooks/stripe` | Stripe-Signature header | Handles payment/subscription webhook events |

### Admin Subscription — `/api/admin/subscriptions`
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/api/admin/subscriptions` | AdminOnly | Paginated subscription list with MRR summary |

### Super Admin Plans — `/api/superadmin/subscription-plans`
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/api/superadmin/subscription-plans` | SuperAdminOnly | List all plans |
| PATCH | `/api/superadmin/subscription-plans/{id}` | SuperAdminOnly | Update plan config (monthly_fee, commission_rate, priority_delay_seconds, stripe_price_id) |

### Admin Providers — `/api/admin/providers/`
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `verification-queue` | AdminOnly | Get pending document submissions |
| GET | `/` | AdminOnly | Get all providers (filter by tier, category, search, isOnline, isSuspended) |
| GET | `stats` | AdminOnly | Aggregate counts: total, active, pendingVerification, suspended |
| GET | `{providerId}` | AdminOnly | Full provider detail (profile, rating stats, tier history, documents) |
| POST | `{providerId}/verify-documents` | AdminOnly | Approve or reject provider documents |
| POST | `{providerId}/suspend` | AdminOnly | Suspend provider (body: `{ reason }`, min 10 chars); fires `AccountSuspended` SignalR |
| POST | `{providerId}/reinstate` | AdminOnly | Reinstate suspended provider; fires `AccountReinstated` SignalR |

### Admin Jobs — `/api/admin/jobs/`
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/` | AdminOnly | Paginated job list (search, status, from/to date filters, page/pageSize) |
| GET | `{jobId}` | AdminOnly | Full job detail (photos, status history, rating, transaction) |
| POST | `{jobId}/force-cancel` | AdminOnly | Force-cancel a job — only Pending or Accepted → Expired; sends customer notification |

### Admin Disputes — `/api/admin/disputes/`
| Method | Route | Auth | Description |
|---|---|---|---|
| GET | `/` | AdminOnly | Paginated dispute list with aggregate counts (openCount, resolvedCount, rejectedCount) |
| GET | `{disputeId}` | AdminOnly | Full dispute detail (job data, photos, status history, complaint) |
| POST | `{disputeId}/resolve` | AdminOnly | Resolve dispute: `action` = `approve_refund` (Stripe refund) or `reject` (release to provider) |

### Landing — `/api/landing/` (public, no auth)
| Method | Route | Description |
|---|---|
| GET | `stats` | Live platform stats: totalProviders (Active tier), totalJobsCompleted (Paid jobs), averageRating, citiesCovered |
| POST | `contact` | Submit contact inquiry → inserts row in `public.contact_inquiries` |

Controller: `Khudmati.API/Controllers/LandingController.cs`  
Query: `Khudmati.API/Domain/Queries/GetLandingStatsQuery.cs`  
Command: `Khudmati.API/Domain/Commands/SubmitContactInquiryCommand.cs`  
Both actions use `[AllowAnonymous]`.

## Provider Verification System

### Tier Progression
```
Unverified → PhoneVerified → IdVerified → SkillTested → Active
```
- **Unverified**: Registered but no documents submitted
- **PhoneVerified**: OTP verified at registration
- **IdVerified**: ID documents approved by admin
- **SkillTested**: Passed skill test (7/10 correct)
- **Active**: All steps complete — can see and accept jobs

### Schema (providers schema)
- `providers.accounts.verification_tier` — VARCHAR(30) enum
- `providers.document_submissions` — ID upload records with admin review status
- `providers.skill_test_questions` — 10 questions per category (seeded data)
- `providers.skill_test_sessions` — Test attempts with cooldown tracking
- `providers.tier_history` — Audit log of tier changes

### Business Rules
- Only **Active** tier providers join `providers-available` SignalR group
- Skill test: 10 multiple-choice questions, 7/10 to pass, 24h cooldown on failure
- Document upload: max 5MB per file, jpg/png/pdf only
- Admin manual review required for ID verification
- Tier changes logged with adminId and timestamp

### SignalR Events
- `VerificationStatusChanged` → fires to `provider-{providerId}` group when documents approved/rejected

## SignalR — `/hubs/jobs`
JWT auth required. Groups joined automatically in `OnConnectedAsync` based on `aud` claim:
- Providers → join groups `providers-available` (only if **Active** tier) AND `provider-{userId}` (all providers)
- Customers → join group `customer-{userId}`

| Event (server→client) | Triggered by | Group | Payload |
|---|---|---|---|
| `NewJobAvailable` | Job created | `providers-available` | `{ jobId, categoryId, distanceKm, ... }` |
| `JobAccepted` | Provider accepts | `customer-{customerId}` | `{ jobId, provider: { name, phone, ... } }` |
| `JobExpired` | Background expiry | `customer-{customerId}` | `{ jobId }` |
| `JobStatusChanged` | Job status advances | `customer-{customerId}` | `{ jobId, status, updatedAt }` |
| `PaymentHeld` | Job marked Completed | `customer-{customerId}` | `{ jobId, amount, releaseDate }` |
| `PaymentReleased` | Background releases funds | `provider-{providerId}` | `{ jobId, netAmount, currency }` |
| `VerificationStatusChanged` | Admin approves/rejects documents | `provider-{providerId}` | `{ newTier, status, message }` |
| `ProviderLocationUpdated` | Provider sends location (EnRoute) | `customer-{customerId}` | `{ jobId, latitude, longitude, timestamp }` |
| `NewChatMessage` | Chat message sent | `customer-{customerId}` or `provider-{providerId}` (other party only) | `{ id, jobId, senderId, senderType, text, sentAt }` |
| `DisputeOpened` | Customer raises dispute | `provider-{providerId}` | `{ jobId, disputeId, complaint }` |
| `DisputeResolved` | Admin resolves dispute | `customer-{customerId}` and `provider-{providerId}` | `{ disputeId, jobId, action, message }` (action: `approve_refund` or `reject`) |
| `AccountSuspended` | Admin suspends provider | `provider-{providerId}` | `{ reason }` |
| `AccountReinstated` | Admin reinstates provider | `provider-{providerId}` | `{}` |

Event handlers live in `Khudmati.API/EventHandlers/` (MediatR `INotificationHandler`). They reference both module domain events and `IHubContext<JobHub>`. Registered via:
```csharp
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(JobCreatedEventHandler).Assembly));
```

## Background services
- `JobExpiryService` — polls every 30s for `Status = Pending` and `ExpiresAt < UtcNow`. Sends `ExpireJobCommand` per expired job.
- `PaymentReleaseService` — polls every 5min for `Status = Held` and `HoldUntil <= UtcNow`. Sends `ReleasePaymentCommand` per transaction (triggers Stripe Transfer → provider payout). Both use scoped `IMediator` and are registered with `AddHostedService<>()`.

## PostgreSQL patterns
- **Reference number sequence**: ADO.NET `ExecuteScalarAsync("SELECT nextval('bookings.job_reference_seq')")` — raw command on the EF connection.
- **SELECT FOR UPDATE** (race-safe accept): `await _context.Database.ExecuteSqlAsync($"SELECT id FROM bookings.jobs WHERE id = {jobId} FOR UPDATE")` inside `BeginTransactionAsync()`, then regular EF fetch and update.
- **Upsert provider location**: Raw `INSERT ... ON CONFLICT (provider_id) DO UPDATE SET ...` via `ExecuteSqlAsync` with FormattableString (EF8 parameterizes automatically). Used both for initial location registration and for live GPS tracking during EnRoute.
- **Haversine distance filter**: Implemented in C# on `GetAvailableJobsQuery` and client-side in Flutter `distance_utils.dart` — no PostGIS dependency.

## Live GPS Tracking (Feature #08)
When a job's status = `EnRoute`, the provider app automatically broadcasts GPS location every 3 seconds:
- **Provider side**: `ActiveJobNotifier` starts `Timer.periodic(3s)` → `POST /tracking/jobs/{jobId}/location`
- **Backend**: `UpdateProviderLocationCommand` validates job status, upserts location, fires SignalR event
- **Customer side**: `JobTrackingNotifier` subscribes to `ProviderLocationUpdated` → updates map pin with smooth animation
- **Validation**: Rejects 0,0 coordinates (GPS initialization artifact) and out-of-range lat/lng
- **Battery optimization**: Stops immediately on status transition to InProgress
- **No location history stored** — only current location in `providers.locations` table

## Post-Job Photo Requirement (Feature #11)
- `bookings.job_photos` has a `photo_type TEXT NOT NULL DEFAULT 'before' CHECK (photo_type IN ('before', 'after'))` column
- Photos uploaded via `POST /api/bookings/jobs/{jobId}/photos` (CustomerOnly) are saved as `photo_type = 'before'`
- Provider uploads after-photos via `POST /api/providers/jobs/{jobId}/after-photos` (ProviderOnly, job must be InProgress), saved as `photo_type = 'after'`, stored in `wwwroot/uploads/jobs/{jobId}/after/`
- `AdvanceJobStatusCommand` gates the `InProgress → Completed` transition: requires at least 1 after-photo, returns `AFTER_PHOTO_REQUIRED` (HTTP 422) otherwise
- All job DTOs return `beforePhotoUrls` and `afterPhotoUrls` as separate lists instead of a single `photoUrls`

## Shared services (registered in Program.cs)
- `IJwtService` → `JwtService` — token generation + BCrypt wrappers
- `IOtpNotificationService` → `ConsoleOtpNotificationService` — OTP delivery stub
- `IAdminRepository` → `AdminRepository` — admin account + refresh token persistence

## Database schemas
Each module owns its schema. Table names follow snake_case.
All EF configurations are in `Program.cs` via `AppDbContext.AdditionalModelConfiguration`.
Migrations are run from `Khudmati.API`.

## Adding a new module
1. Create `src/Modules/{Name}/Khudmati.Modules.{Name}/`
2. Add `{Name}Module.cs` with `Add{Name}Module(this IServiceCollection)` extension
3. Register in `Program.cs`
4. Add project reference to `Khudmati.API.csproj`
5. Add all entity Fluent API config inside `AppDbContext.AdditionalModelConfiguration` in `Program.cs`
6. Use `_context.Set<T>()` in repositories — no DbSet properties on AppDbContext
