# Feature: Payments

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer, mobile-provider)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#04 must be implemented first. Payments trigger after job reaches `Completed` status.

## Goal
Implement on-platform payments: the customer pays when confirming a booking, the platform holds the funds, deducts 15–20% commission, and releases the remainder to the provider 24 hours after job completion (dispute window). This completes Phase 1 — the full transaction loop is closed.

## Platforms Affected
- [x] Customer Mobile App (Flutter) — payment entry at booking confirmation
- [x] Provider Mobile App (Flutter) — payout status and earnings summary
- [x] Backend (.NET 8) — payment processing, commission, payout release
- [ ] Admin Panel — feature #12
- [ ] Web Landing Page
- [ ] Web Super Admin Panel

---

## User Stories
- As a **customer**, I want to pay for the service securely through the app so I don't need to handle cash.
- As a **provider**, I want to receive my earnings automatically after the job is completed so I don't have to chase payment.
- As the **platform**, I want to deduct commission before releasing funds to the provider so the business model is enforced.
- As the **platform**, I want a 24-hour hold after job completion before releasing funds so disputes can be raised first.

---

## Payment Flow (end to end)

```
1. Customer confirms booking (feature #02)
   → Create payment intent with provider (Stripe)
   → Store transaction record: status = Pending

2. Provider marks job Completed (feature #04)
   → Transaction status → Held (24-hour dispute window starts)
   → Fire SignalR event PaymentHeld to customer

3. 24 hours pass with no dispute raised
   → Background service releases funds
   → Deduct commission (15–20%) from gross amount
   → Transfer net amount to provider's Stripe connected account
   → Transaction status → Released
   → Fire SignalR event PaymentReleased to provider

4. (Alternative) Dispute raised within 24 hours
   → Transaction status → Disputed (feature #13 handles resolution)
```

---

## Payment Provider

Use **Stripe** for V1:
- Customer payments via **Stripe Payment Intents** (card, Apple Pay, Google Pay)
- Provider payouts via **Stripe Connect** (Express accounts)
- Commission deducted via Stripe's `application_fee_amount` parameter

For V1, use Stripe **test mode** only. Wire up the real integration but keep test keys in config — switching to live is a config change, not a code change.

Abstract the payment provider behind an interface `IPaymentProvider` so it can be swapped later:
```csharp
// Khudmati.Shared or Khudmati.Modules.Payments
public interface IPaymentProvider
{
    Task<CreatePaymentIntentResult> CreatePaymentIntentAsync(decimal amount, string currency, string customerId);
    Task<ConfirmPaymentResult> ConfirmPaymentAsync(string paymentIntentId);
    Task<TransferResult> TransferToProviderAsync(string providerAccountId, decimal amount, string currency);
    Task<OnboardProviderResult> CreateProviderAccountAsync(string email, string phone);
}
```
Implement `StripePaymentProvider : IPaymentProvider` in `Modules/Payments/Infrastructure/Stripe/`.

---

## Commission Rules

```
Commission rate = 20% for all providers in V1
Net to provider = gross_amount - (gross_amount × commission_rate)

Example: Customer pays $50
  Commission = $50 × 0.20 = $10 → platform keeps this
  Provider receives = $50 - $10 = $40
```

Store commission rate on the transaction at time of payment (not calculated later) so rate changes don't affect historical transactions.

---

## Customer App Changes

### Update: Booking Summary Screen (`lib/features/booking/presentation/booking_summary_screen.dart`)
Add payment section before the confirm button:

- Price field: text input — "أدخل الأجر المتفق عليه" (Enter the agreed price)
  - Numeric keyboard, currency prefix (e.g. $ or LBP — read from app config)
  - Required — confirm button disabled until amount is entered and > 0
  - Helper text: "يتم الاتفاق على السعر مع المزود قبل تأكيد الحجز" (Price agreed with provider before confirming)
- Payment method selector: show saved cards or "Add card" button
  - Use Stripe's prebuilt `PaymentSheet` Flutter SDK — do not build a custom card form
  - On "Confirm Booking" tap → launch PaymentSheet → on success → call backend to create job

### New Screen: Payment Receipt (`lib/features/payments/presentation/payment_receipt_screen.dart`)
Shown after successful payment and job creation:
- Checkmark animation
- Amount paid, job reference number, payment method last 4 digits
- "عرض الطلب" (View Booking) → navigates to job tracking screen

### New Screen: Payment Status (`lib/features/payments/presentation/payment_status_screen.dart`)
Reachable from booking history — shows payment lifecycle for a past job:
- Amount paid, commission note: "شامل رسوم الخدمة" (Includes service fee)
- Status chip: Pending / Held / Released / Disputed / Refunded
- Release date shown when status is Held: "سيتم الإفراج عن الدفعة بتاريخ {date}"

---

## Provider App Changes

### New Screen: Earnings (`lib/features/earnings/presentation/earnings_screen.dart`)
- Total earned this month (net after commission)
- Total earned all time
- List of past transactions: job reference, service category, gross amount, commission deducted, net received, status chip, date
- Pull-to-refresh

### New Screen: Payout Status (`lib/features/earnings/presentation/payout_status_screen.dart`)
- Current pending balance (jobs completed, in 24h hold)
- Available balance (released, pending bank transfer)
- Stripe Connect onboarding button: "ربط حساب الدفع" (Connect payment account) — launches Stripe Connect onboarding flow
  - Show only if provider hasn't completed Stripe Connect onboarding yet
  - After onboarding: show connected bank account last 4 digits

### Update: Job Completion Screen
After provider marks job `Completed`, show:
- "تم إنهاء العمل! سيتم تحويل أتعابك خلال 24 ساعة" (Job done! Your earnings will be transferred within 24 hours)
- Expected payout date and net amount

---

## API Endpoints

### POST /api/payments/intent
- Auth: Customer JWT
- Purpose: Create a Stripe PaymentIntent before booking is confirmed
- Request:
```json
{
  "amount": 50.00,
  "currency": "usd",
  "categoryId": "plumbing"
}
```
- Response:
```json
{
  "success": true,
  "data": {
    "paymentIntentId": "pi_xxx",
    "clientSecret": "pi_xxx_secret_xxx",
    "amount": 50.00,
    "currency": "usd"
  }
}
```
- Business rules:
  - `clientSecret` is returned to Flutter — passed to Stripe's `PaymentSheet` to complete payment on device
  - Amount must be > 0 and within reasonable bounds (max $10,000)
  - Store intent in `payments.transactions` with status `Pending`

### POST /api/payments/confirm
- Auth: Customer JWT
- Purpose: Called after Stripe confirms payment on device — attach payment to job
- Request:
```json
{
  "paymentIntentId": "pi_xxx",
  "jobId": "uuid"
}
```
- Response:
```json
{
  "success": true,
  "data": {
    "transactionId": "uuid",
    "status": "Paid",
    "amount": 50.00,
    "commissionAmount": 10.00,
    "netToProvider": 40.00
  }
}
```
- Business rules:
  - Verify payment intent status with Stripe API — must be `succeeded`
  - Link transaction to job
  - Update job status in Bookings module: `Completed → Paid` (via domain event, not direct DB call)
  - Calculate commission and net amount, store on transaction

### POST /api/payments/jobs/{jobId}/release (internal — called by background service)
- Auth: Internal service call (no JWT — use a shared internal API key in headers)
- Purpose: Release held funds to provider after 24-hour window
- Business rules:
  - Check transaction status = `Held` and `hold_until < now()`
  - Call Stripe Connect transfer API: transfer `net_amount` to provider's connected account
  - Update transaction status → `Released`
  - Fire SignalR `PaymentReleased` event to provider group `provider-{providerId}`

### GET /api/payments/my-transactions
- Auth: Customer JWT or Provider JWT
- Response: paginated list of transactions for the authenticated user
- Customer sees: amount paid, job reference, status, date
- Provider sees: gross amount, commission, net received, status, date

### GET /api/providers/earnings/summary
- Auth: Provider JWT
- Response:
```json
{
  "success": true,
  "data": {
    "pendingBalance": 40.00,
    "availableBalance": 120.00,
    "totalEarnedAllTime": 580.00,
    "totalEarnedThisMonth": 160.00,
    "currency": "usd",
    "stripeConnectStatus": "connected" | "pending" | "not_started"
  }
}
```

### POST /api/providers/stripe/onboard
- Auth: Provider JWT
- Purpose: Generate Stripe Connect onboarding link
- Response: `{ "success": true, "data": { "onboardingUrl": "https://connect.stripe.com/..." } }`
- Business rules: Create Stripe Express account if not exists, generate account link, return URL for Flutter to open in WebView or browser

---

## Data Model

```sql
-- payments schema

CREATE TABLE payments.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL,                        -- references bookings.jobs(id) — cross-schema ref, no FK
    customer_id UUID NOT NULL,
    provider_id UUID NOT NULL,
    stripe_payment_intent_id VARCHAR(100) UNIQUE,
    gross_amount DECIMAL(10, 2) NOT NULL,
    commission_rate DECIMAL(5, 4) NOT NULL,      -- e.g. 0.2000 = 20%
    commission_amount DECIMAL(10, 2) NOT NULL,
    net_amount DECIMAL(10, 2) NOT NULL,          -- gross - commission
    currency VARCHAR(10) NOT NULL DEFAULT 'usd',
    status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    -- status values: Pending, Paid, Held, Released, Disputed, Refunded
    hold_until TIMESTAMPTZ,                      -- set to completed_at + 24h when job completes
    stripe_transfer_id VARCHAR(100),             -- set when funds released to provider
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_job_id ON payments.transactions(job_id);
CREATE INDEX idx_transactions_customer_id ON payments.transactions(customer_id);
CREATE INDEX idx_transactions_provider_id ON payments.transactions(provider_id);
CREATE INDEX idx_transactions_status ON payments.transactions(status);

-- Provider Stripe Connect accounts
CREATE TABLE payments.provider_stripe_accounts (
    provider_id UUID PRIMARY KEY,
    stripe_account_id VARCHAR(100) UNIQUE NOT NULL,
    onboarding_status VARCHAR(30) NOT NULL DEFAULT 'pending',
    -- onboarding_status: pending, complete
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Backend Structure

```
Modules/Payments/Khudmati.Modules.Payments/
├── Domain/
│   ├── Entities/
│   │   ├── Transaction.cs
│   │   └── ProviderStripeAccount.cs
│   ├── Enums/
│   │   └── TransactionStatus.cs
│   └── Events/
│       ├── PaymentConfirmedEvent.cs
│       └── PaymentReleasedEvent.cs
├── Application/
│   ├── Commands/
│   │   ├── CreatePaymentIntentCommand.cs + Handler + Validator
│   │   ├── ConfirmPaymentCommand.cs + Handler + Validator
│   │   ├── ReleasePaymentCommand.cs + Handler      ← called by background service
│   │   └── OnboardProviderStripeCommand.cs + Handler
│   ├── Queries/
│   │   ├── GetMyTransactionsQuery.cs + Handler
│   │   └── GetProviderEarningsSummaryQuery.cs + Handler
│   └── DTOs/
│       ├── PaymentIntentDto.cs
│       ├── TransactionDto.cs
│       └── EarningsSummaryDto.cs
├── Infrastructure/
│   ├── Stripe/
│   │   └── StripePaymentProvider.cs              ← implements IPaymentProvider
│   ├── Persistence/
│   │   └── TransactionRepository.cs
│   └── BackgroundJobs/
│       └── PaymentReleaseService.cs              ← IHostedService, runs every 5 min
└── PaymentsModule.cs
```

---

## Payment Release Background Service

```csharp
// Infrastructure/BackgroundJobs/PaymentReleaseService.cs
public class PaymentReleaseService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            await ProcessReleasesAsync(ct);
            await Task.Delay(TimeSpan.FromMinutes(5), ct);
        }
    }

    private async Task ProcessReleasesAsync(CancellationToken ct)
    {
        // Query transactions where status = 'Held' AND hold_until < now()
        // For each: send ReleasePaymentCommand via MediatR
        // Wrap each in try/catch — one failure must not stop the rest
    }
}
```

---

## Real-time / SignalR Events

| Event | Fired when | Sent to | Payload |
|---|---|---|---|
| `PaymentHeld` | Job marked Completed, 24h hold starts | `customer-{customerId}` | `{ jobId, amount, releaseDate }` |
| `PaymentReleased` | Background service releases funds | `provider-{providerId}` | `{ jobId, netAmount, currency }` |

Add these groups to `JobHub`:
- Providers join `provider-{providerId}` group on connect (in addition to `providers-available`)

---

## Update Root CLAUDE.md After This Feature

Add to SignalR events section:
```
- `PaymentHeld` → `customer-{customerId}`
- `PaymentReleased` → `provider-{providerId}`
```

Add provider group to SignalR groups section:
```
- `provider-{providerId}` — one group per provider (for personal events like payment released)
```

---

## Edge Cases & Validation

- Customer submits payment with amount = 0 → `400 "INVALID_AMOUNT"`
- Stripe PaymentIntent fails → return Stripe error message to Flutter, do NOT create job — show "فشل الدفع، يرجى المحاولة" (Payment failed, please try again)
- Job marked Completed but no transaction exists → log error, do not crash — admin must resolve manually
- Provider hasn't completed Stripe Connect onboarding when release runs → skip release, log warning, retry next cycle
- Payment release fails (Stripe API down) → keep status as `Held`, retry on next background service cycle — never mark Released until Stripe confirms
- Double payment attempt on same job → `409 "PAYMENT_ALREADY_EXISTS"` (check `job_id` uniqueness in transactions)
- Customer disputes within 24h → transaction moves to `Disputed` — background service skips `Disputed` transactions (feature #13 handles resolution)

---

## Out of Scope (do not implement)
- Dispute resolution — feature #13
- Refunds — feature #13
- Cash payment option — V2
- Invoice generation / PDF receipts — V2
- Multi-currency support beyond config default — V2
- Subscription billing — V2 (post-launch)
- Commission tier based on provider rating — V2

---

## Acceptance Criteria
- [ ] Customer can enter a price, complete Stripe PaymentSheet, and have payment recorded against the job
- [ ] Transaction record created with correct gross, commission (20%), and net amounts
- [ ] Job transitions to `Paid` after payment confirmed
- [ ] Provider receives `PaymentHeld` SignalR event showing expected payout date
- [ ] Background service releases payment after 24 hours and fires `PaymentReleased` to provider
- [ ] `Disputed` transactions are skipped by the release service
- [ ] Provider can complete Stripe Connect onboarding via in-app flow
- [ ] Provider earnings summary shows correct pending and available balances
- [ ] Payment failure does not create a job — customer is shown an error and stays on booking screen
- [ ] `IPaymentProvider` interface abstracts Stripe — no Stripe-specific code outside `Infrastructure/Stripe/`
- [ ] All Flutter screens render correctly in RTL Arabic layout
