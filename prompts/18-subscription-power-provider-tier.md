# Feature: Subscription / Power Provider Tier

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-provider), React + TypeScript (web-admin, web-superadmin)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#05 and #07 must be implemented. Provider must be `Active` tier to subscribe. Stripe Connect must already be set up (feature #05).

## Goal
Introduce a voluntary **"Power Provider"** monthly subscription. Standard providers remain on the default 15–20% commission with no monthly fee. Power Providers pay a fixed monthly fee via Stripe, receive a reduced 10% commission rate, and get first-refusal priority when new jobs are broadcast. This creates a sustainable secondary revenue stream while rewarding high-performing providers.

## Platforms Affected
- [x] Provider Mobile App (Flutter)
- [x] Backend (.NET 8)
- [x] Web Admin Panel (React + TypeScript) — subscription stats overview
- [x] Web Super Admin Panel (React + TypeScript) — plan configuration, MRR tracking
- [ ] Customer Mobile App — no changes
- [ ] Web Landing Page — no changes in V1

---

## User Stories
- As a **provider**, I want to subscribe to Power Provider so I get a lower commission and see jobs before other providers.
- As a **provider**, I want to manage (pause, cancel) my subscription from the app so I stay in control of my costs.
- As an **admin**, I want to see how many providers are subscribed so I can monitor adoption.
- As a **super admin**, I want to configure subscription plan pricing and commission rates so I can adjust the business model without a code deploy.

---

## Subscription Tiers

| Tier | Monthly Fee | Commission Rate | Job Priority |
|---|---|---|---|
| Standard | Free | 15% | Normal |
| Power Provider | 99 SAR / month (configurable) | 10% | Priority +1 window (see below) |

**Priority window logic:** When a new job is broadcast via SignalR `NewJobAvailable`, Power Providers receive it 30 seconds before Standard providers. After 30 seconds, if no Power Provider has accepted, the job is broadcast to all `providers-available` SignalR group members. Implement with a `Task.Delay` + conditional broadcast in `JobHub` or the job creation handler.

---

## Database Changes

All new tables go in the `providers` schema.

### New table: `providers.subscription_plans`
Admin-managed, read by backend at runtime.
```sql
CREATE TABLE providers.subscription_plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(50) NOT NULL,          -- 'PowerProvider'
    monthly_fee     NUMERIC(10,2) NOT NULL,         -- 99.00
    commission_rate NUMERIC(5,2) NOT NULL,           -- 10.00 (percent)
    priority_delay_seconds INT NOT NULL DEFAULT 30, -- head-start seconds before Standard
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Seed one row: `('PowerProvider', 99.00, 10.00, 30, true)`.

### New table: `providers.provider_subscriptions`
```sql
CREATE TABLE providers.provider_subscriptions (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id            UUID NOT NULL REFERENCES providers.providers(id) ON DELETE CASCADE,
    plan_id                UUID NOT NULL REFERENCES providers.subscription_plans(id),
    stripe_subscription_id VARCHAR(100) NOT NULL UNIQUE,
    stripe_customer_id     VARCHAR(100) NOT NULL,
    status                 VARCHAR(20) NOT NULL DEFAULT 'Active',
    -- Active | PastDue | Cancelled | Paused
    current_period_start   TIMESTAMPTZ NOT NULL,
    current_period_end     TIMESTAMPTZ NOT NULL,
    cancelled_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_provider_subscriptions_active
    ON providers.provider_subscriptions(provider_id)
    WHERE status IN ('Active', 'PastDue'); -- only one active sub per provider
```

### EF Configuration
Add entity configurations in `Program.cs` via `AppDbContext.AdditionalModelConfiguration`. No DbSet properties on AppDbContext — use `_context.Set<T>()`.

### Commission rate resolution
In the payment release command (feature #05), when calculating commission:
1. Query `providers.provider_subscriptions` for an `Active` subscription for the provider.
2. If found, use `subscription_plans.commission_rate`; otherwise use default rate (15%).
3. Store the applied commission rate in `payments.transactions` (add column `commission_rate_applied NUMERIC(5,2)`).

---

## Backend Changes

### Module: `Modules/Providers/`

#### 1. Subscribe command — new

**File:** `Modules/Providers/Application/Commands/SubscribePowerProviderCommand.cs`
```csharp
public record SubscribePowerProviderCommand(Guid ProviderId, string PaymentMethodId) : IRequest<Result<SubscribeResult>>;
```

**Handler logic:**
1. Verify provider tier is `Active` — only Active providers can subscribe → `PROVIDER_NOT_ACTIVE`.
2. Check no existing `Active` or `PastDue` subscription → `ALREADY_SUBSCRIBED`.
3. Load active subscription plan.
4. If provider has no Stripe customer ID, create one via `stripe.customers.create` and store.
5. Attach `PaymentMethodId` to Stripe customer as default payment method.
6. Create Stripe subscription: `stripe.subscriptions.create({ customer, items: [{ price: plan.stripe_price_id }] })`.
7. Insert `providers.provider_subscriptions` row with `status = Active`.
8. Return `{ subscriptionId, currentPeriodEnd }`.

#### 2. Cancel subscription command — new

**File:** `Modules/Providers/Application/Commands/CancelSubscriptionCommand.cs`

**Handler logic:**
1. Load active subscription for provider.
2. Cancel at period end via Stripe: `stripe.subscriptions.update(id, { cancel_at_period_end: true })`.
3. Note: do NOT immediately change status — let the webhook handle it.
4. Return `{ cancelsAt: current_period_end }`.

#### 3. Stripe webhook handler — new endpoint

**File:** `Khudmati.API/Controllers/StripeWebhookController.cs` (add to existing or create new)

Handle events:
- `invoice.payment_succeeded` → ensure subscription status is `Active`
- `invoice.payment_failed` → set status to `PastDue`; send push notification to provider
- `customer.subscription.deleted` → set status to `Cancelled`, set `cancelled_at`

Always verify Stripe webhook signature using `StripeClient.ConstructEvent` before processing.

#### 4. Priority broadcast logic — update job creation

In the command/handler that fires `NewJobAvailable` via SignalR:

```csharp
// Broadcast to Power Providers first
await _hubContext.Clients.Group("providers-power").SendAsync("NewJobAvailable", payload);

// After priority delay, broadcast to all remaining active providers
_ = Task.Run(async () => {
    await Task.Delay(TimeSpan.FromSeconds(plan.PriorityDelaySeconds));
    // Only broadcast if job is still Pending (not yet accepted)
    var job = await _jobRepository.GetByIdAsync(jobId);
    if (job.Status == JobStatus.Pending)
        await _hubContext.Clients.Group("providers-available").SendAsync("NewJobAvailable", payload);
});
```

Maintain a `providers-power` SignalR group — providers with an `Active` subscription join this group in addition to `providers-available` on connect.

#### 5. Subscription info query — new

**File:** `Modules/Providers/Application/Queries/GetSubscriptionInfoQuery.cs`

Returns current plan, status, next billing date, commission rate, cancellation date (if scheduled).

---

## API Endpoints

### GET /api/providers/me/subscription
Returns current subscription state.
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "plan": "PowerProvider",
    "status": "Active",
    "monthlyFee": 99.00,
    "commissionRate": 10.0,
    "currentPeriodEnd": "2026-05-04T00:00:00Z",
    "cancelsAtPeriodEnd": false,
    "currency": "SAR"
  }
}
```
If not subscribed: `"data": null`.

### POST /api/providers/me/subscription
Subscribe to Power Provider plan.
- Auth: Provider JWT
- Request: `{ "paymentMethodId": "pm_xxx" }`
- Response: `{ "success": true, "data": { "subscriptionId": "sub_xxx", "currentPeriodEnd": "..." } }`
- Error codes: `PROVIDER_NOT_ACTIVE`, `ALREADY_SUBSCRIBED`, `PAYMENT_METHOD_INVALID`, `STRIPE_ERROR`

### DELETE /api/providers/me/subscription
Cancel subscription at period end.
- Auth: Provider JWT
- Response: `{ "success": true, "data": { "cancelsAt": "2026-05-04T00:00:00Z" } }`

### POST /api/webhooks/stripe *(add subscription events to existing handler)*
- Auth: Stripe-Signature header verification (no JWT)

---

## Provider App Changes

### New Screen: Subscription Screen (`lib/features/subscription/presentation/subscription_screen.dart`)

**Layout (unauthenticated / Standard tier):**
- AppBar: "باقة المزود المتميز" (Power Provider Plan)
- Hero card (amber gradient):
  - Badge: "⭐ مزود متميز"
  - Headline: "وفّر على عمولتك، احصل على وظائف أولاً"
  - Sub: "10% فقط بدلاً من 15% عمولة + أولوية في الحجوزات"
- Feature comparison table:
  | | عادي | متميز ⭐ |
  | العمولة | 15% | 10% |
  | أولوية الوظائف | — | ✓ |
  | شارة متميز | — | ✓ |
  | الرسوم الشهرية | مجاناً | ٩٩ ر.س |
- Subscribe button (amber): "اشترك للآن — ٩٩ ر.س / شهر"
  - Opens Stripe payment sheet (using existing `flutter_stripe` integration from feature #05)
- Terms note: "يُجدَّد تلقائياً — يمكن الإلغاء في أي وقت"

**Layout (subscribed):**
- Status card (brand blue): "أنت مزود متميز ⭐"
  - Next billing: "التجديد القادم: ٤ مايو ٢٠٢٦"
  - Commission rate: "عمولتك: 10%"
- "إلغاء الاشتراك" (Cancel subscription) — destructive confirmation dialog before calling API

### Update: Provider Profile Screen
- Add a "مزود متميز ⭐" amber badge next to the provider name when subscribed
- Add "إدارة الاشتراك" (Manage Subscription) tile pointing to the Subscription Screen

### State Management

New Riverpod provider: `lib/features/subscription/presentation/subscription_provider.dart`

```dart
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  Future<SubscriptionState?> build() async =>
      ref.read(subscriptionRepositoryProvider).getSubscription();

  Future<void> subscribe(String paymentMethodId) async { ... }
  Future<void> cancel() async { ... }
}
```

New repository: `lib/features/subscription/data/subscription_repository.dart`

---

## Admin Panel Changes (`web-admin/`)

### Update: Provider Detail Page
Add a "Subscription" section showing:
- Current plan name and status
- Commission rate applied
- Next billing date (if Active)

### New Page: Subscription Overview (`web-admin/src/pages/subscriptions/SubscriptionOverviewPage.tsx`)
Route: `/subscriptions`

- Table: Provider name | Plan | Status | Monthly fee | Since | Next billing
- Status chips: Active (green), PastDue (amber), Cancelled (red)
- Summary cards at top: Total Active, MRR (Monthly Recurring Revenue), Churn this month

---

## Super Admin Panel Changes (`web-superadmin/`)

### New Page: Subscription Plan Config (`web-superadmin/src/pages/plans/PlansPage.tsx`)
Route: `/plans`

- View current plan settings (monthly fee, commission rate, priority delay)
- Edit inline: save calls `PATCH /api/admin/subscription-plans/{id}` (super admin JWT)
- Toggle plan active/inactive (inactive plan hides subscribe button in provider app)
- Stripe Price ID field (the Stripe `price_*` ID linked to this plan)

Add endpoint: `PATCH /api/superadmin/subscription-plans/{id}` — Super Admin JWT required.

---

## Notifications

- **Subscription activated:** push to provider — "مرحباً بك في باقة المزود المتميز ⭐ عمولتك الآن 10%"
- **Payment failed:** push to provider — "تعذّر تجديد اشتراكك. يرجى تحديث طريقة الدفع"
- **Subscription cancelled:** push to provider (when deletion webhook fires) — "انتهى اشتراكك المتميز في [date]"

---

## Edge Cases & Validation

- A provider cannot subscribe if their tier is below `Active`
- If the Stripe subscription charge fails, set status to `PastDue` and keep the reduced commission rate for a 3-day grace period before reverting to Standard
- If a provider cancels mid-month, they retain Power Provider benefits until `current_period_end`
- Two simultaneous subscribe requests must not create duplicate Stripe subscriptions — use the `UNIQUE INDEX` on the table + idempotency key on Stripe API calls
- Webhook events must be idempotent — check if status is already in desired state before updating
- `providers-power` SignalR group must be updated when subscription status changes (join on activate, leave on cancel/past_due)

---

## Out of Scope (do not implement)
- Annual billing option
- Multiple plan tiers (just two for V1: Standard and Power Provider)
- Team/agency accounts
- Promotional free trials
- Commission rate variation per category
- Customer-facing display of provider subscription badge

---

## File Locations

| File | Purpose |
|---|---|
| `Modules/Providers/Application/Commands/SubscribePowerProviderCommand.cs` | Subscribe command + handler |
| `Modules/Providers/Application/Commands/CancelSubscriptionCommand.cs` | Cancel command + handler |
| `Modules/Providers/Application/Queries/GetSubscriptionInfoQuery.cs` | Subscription info query |
| `Khudmati.API/Controllers/ProvidersController.cs` | Add subscription endpoints |
| `Khudmati.API/Controllers/StripeWebhookController.cs` | Handle subscription webhook events |
| `lib/features/subscription/presentation/subscription_screen.dart` | Subscription screen |
| `lib/features/subscription/presentation/subscription_provider.dart` | Riverpod state |
| `lib/features/subscription/data/subscription_repository.dart` | API calls |
| `web-admin/src/pages/subscriptions/SubscriptionOverviewPage.tsx` | Admin subscription stats |
| `web-superadmin/src/pages/plans/PlansPage.tsx` | Super admin plan config |

---

## Acceptance Criteria
- [ ] A provider with `Active` tier can subscribe by providing a Stripe payment method
- [ ] Subscribed provider's commission is 10% on all subsequent jobs
- [ ] Power Providers receive the `NewJobAvailable` SignalR event 30 seconds before Standard providers
- [ ] Stripe webhook correctly transitions subscription status on payment success / failure / cancellation
- [ ] Provider can cancel; benefits persist until period end
- [ ] Provider app shows correct plan status, billing date, and commission rate
- [ ] Admin panel shows subscription overview table and MRR
- [ ] Super admin can edit plan pricing and commission rate without a code deploy
- [ ] All UI text is in Arabic; layout is RTL
