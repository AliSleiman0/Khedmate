# Feature: Referral System

## Context
You are working on **Khudmati (خدمتي)**, a two-sided home services marketplace for MENA markets.
- Backend: ASP.NET Core modular monolith — modules: Bookings, Providers, Customers, Payments, Notifications
- Database: PostgreSQL (schema-per-module)
- Real-time: SignalR — JobHub at `Modules/Notifications/Infrastructure/Hubs/JobHub.cs`
- Frontend: Flutter (mobile-customer)
- Brand: Blue #1B4F72, Amber #F39C12 | Fonts: Cairo (Arabic) + Inter (English) | RTL-first UI
- Project path: C:\Khedmate - ANJU_Context
- Prerequisites: Features #01–#05 must be implemented. Referral credit is triggered when the referred customer's first booking reaches `Paid` status.

## Goal
A double-sided referral programme: every customer gets a unique shareable code. When a new customer signs up using that code and completes their first paid booking, the referee (new customer) receives a percentage discount on that booking and the referrer receives platform credit applied to their next booking. This incentivises organic word-of-mouth growth with minimal fraud surface.

## Platforms Affected
- [x] Customer Mobile App (Flutter)
- [x] Backend (.NET 8)
- [ ] Provider Mobile App — no changes
- [ ] Web Landing Page — no changes in V1
- [ ] Web Admin Panel — referral stats are nice-to-have; out of scope for this prompt
- [ ] Web Super Admin Panel — no changes

---

## User Stories
- As a **customer**, I want to share my referral code with friends so I earn credit when they book their first job.
- As a **new customer**, I want to enter a referral code at signup so I get a discount on my first booking.
- As the **platform**, I want referral credit to be awarded only after a qualifying paid booking so the system cannot be gamed with fake bookings.

---

## Referral Rules (business logic)

| Rule | Value (configurable via constants — do not hard-code) |
|---|---|
| Referee discount | 15% off first booking |
| Referrer credit | 20 SAR platform credit |
| Credit validity | 365 days from award date |
| Qualifying event | Referred customer's first job reaches `Paid` status |
| One-time use | A customer can apply exactly one referral code, ever |
| Self-referral block | Reject if referrer and referee share the same phone number |
| Code format | 8-character uppercase alphanumeric (e.g. `KHUD1A2B`) |
| Credit application | Auto-applied at checkout if balance > 0; cannot exceed booking total |

---

## Database Changes

All new tables go in the `customers` schema.

### New table: `customers.referral_codes`
```sql
CREATE TABLE customers.referral_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    code        VARCHAR(10) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_referral_codes_customer ON customers.referral_codes(customer_id); -- one code per customer
```

### New table: `customers.referral_uses`
Records the link between referrer and referee. Status transitions: `Pending → Completed`.
```sql
CREATE TABLE customers.referral_uses (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_customer_id  UUID NOT NULL REFERENCES customers.customers(id),
    referred_customer_id  UUID NOT NULL REFERENCES customers.customers(id),
    qualifying_booking_id UUID REFERENCES bookings.jobs(id),  -- set when credit is awarded
    referrer_credit_amount NUMERIC(10,2) NOT NULL,
    referee_discount_pct   NUMERIC(5,2)  NOT NULL,
    status                VARCHAR(20) NOT NULL DEFAULT 'Pending', -- Pending | Completed
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at          TIMESTAMPTZ
);
CREATE UNIQUE INDEX idx_referral_uses_referred ON customers.referral_uses(referred_customer_id); -- one referral per new customer
```

### New table: `customers.customer_credits`
Platform credit wallet per customer.
```sql
CREATE TABLE customers.customer_credits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.customers(id) ON DELETE CASCADE,
    amount      NUMERIC(10,2) NOT NULL,       -- always positive; represents remaining balance
    source_type VARCHAR(30) NOT NULL,          -- 'Referral' | 'Promo' | 'Refund'
    source_id   UUID,                          -- referral_uses.id or promo_id etc.
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    used_at     TIMESTAMPTZ                    -- set when fully consumed
);
CREATE INDEX idx_customer_credits_customer ON customers.customer_credits(customer_id);
```

### EF Configuration
Add entity configurations in `Program.cs` via `AppDbContext.AdditionalModelConfiguration` following the existing pattern. Do **not** put configurations in `Khudmati.Shared`.

---

## Backend Changes

### Module: `Modules/Customers/`

#### 1. Auto-generate referral code on customer registration
In `RegisterCustomerCommandHandler` (or the equivalent command that creates the customer record), after saving the customer, generate a unique referral code and insert into `customers.referral_codes`.

Code generation logic:
```csharp
// Simple collision-resistant generator — retry on duplicate key
private static string GenerateCode()
{
    const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no ambiguous chars
    return new string(Enumerable.Range(0, 8)
        .Select(_ => chars[RandomNumberGenerator.GetInt32(chars.Length)])
        .ToArray());
}
```

#### 2. Apply referral code at signup — new command

**File:** `Modules/Customers/Application/Commands/ApplyReferralCodeCommand.cs`
```csharp
public record ApplyReferralCodeCommand(Guid CustomerId, string Code) : IRequest<Result>;
```

**Handler logic:**
1. Load the referral code. If not found → `REFERRAL_CODE_NOT_FOUND`.
2. Check the customer has not already used a referral code (query `referral_uses` for `referred_customer_id = CustomerId`) → `REFERRAL_ALREADY_USED`.
3. Check self-referral: load referrer's phone, load referee's phone — if same → `REFERRAL_SELF_REFERRAL`.
4. Insert a `referral_uses` record with `status = Pending`.
5. Return success.

#### 3. Award referral credit on first paid booking — domain event handler

**File:** `EventHandlers/ReferralAwardHandler.cs` (top-level in `Khudmati.API/EventHandlers/`)

Subscribe to the existing `PaymentReleasedEvent` (or `JobStatusChangedEvent` for `Paid`). When fired:
1. Check if the job's customer has a `Pending` referral use record. If not, exit.
2. Verify this is the customer's **first** paid job (`COUNT(bookings.jobs WHERE customer_id = X AND status = Paid) == 1`).
3. Insert a `customer_credits` row for the **referrer** (`amount = referrer_credit_amount`, `source_type = Referral`, `expires_at = now() + 365 days`).
4. Update `referral_uses.status = Completed`, set `qualifying_booking_id` and `completed_at`.

#### 4. Apply credit at checkout — command change

In `CreateBookingCommandHandler` (or wherever booking price is calculated), before charging the full amount via Stripe:
1. Query available (unexpired, unused) credits for the customer: `SUM(amount)` from `customer_credits` where `customer_id = X AND expires_at > now() AND used_at IS NULL`.
2. Determine `creditToApply = MIN(totalCredits, bookingAmount)`.
3. Reduce the Stripe payment intent by `creditToApply`.
4. After successful payment, mark credit rows as used (starting from oldest-expiring first, partial deductions allowed via a `used_amount` column if needed — keep it simple for V1: mark fully used, create a new row for remaining balance).
5. Return `creditApplied` to the client in the booking confirmation response.

#### 5. Apply referee discount — command change

In `CreateBookingCommandHandler`, if this is the customer's **first** booking AND they have a `Pending` referral use as referee:
1. Compute `discountAmount = bookingAmount * referral_uses.referee_discount_pct / 100`.
2. Apply as a Stripe coupon or reduce payment intent amount.
3. Record the discount in the booking (add a `referral_discount_amount` column to `bookings.jobs` or `payments.transactions`).

---

## API Endpoints

### GET /api/customers/me/referral
Returns the customer's referral code and credit balance.
- Auth: Customer JWT
- Response:
```json
{
  "success": true,
  "data": {
    "code": "KHUD1A2B",
    "shareUrl": "https://khudmati.app/join?ref=KHUD1A2B",
    "creditBalance": 20.00,
    "currency": "SAR",
    "referralsCompleted": 3
  }
}
```

### POST /api/customers/referral/apply
Apply a referral code to the current customer's account. Can only be called once.
- Auth: Customer JWT
- Request: `{ "code": "KHUD1A2B" }`
- Response success: `{ "success": true, "data": { "referrerName": "أحمد", "discountPct": 15 } }`
- Error codes: `REFERRAL_CODE_NOT_FOUND`, `REFERRAL_ALREADY_USED`, `REFERRAL_SELF_REFERRAL`, `REFERRAL_CODE_EXPIRED`

---

## Customer App Changes

### Update: Profile Screen (`lib/features/profile/presentation/profile_screen.dart`)
Add a "دعوة الأصدقاء" (Invite Friends) list tile. Tapping navigates to the Referral Screen.

### New Screen: Referral Screen (`lib/features/referral/presentation/referral_screen.dart`)

**Layout:**
- AppBar: "دعوة الأصدقاء" with back arrow
- Top card (brand blue background):
  - Headline: "شارك كودك، كسب رصيداً" (Share your code, earn credit)
  - Referral code displayed large, with a copy icon
  - "مشاركة" (Share) button — calls native share sheet with deep link URL
- Reward explanation section:
  - Icon + text: "صديقك يحصل على 15% خصم في أول حجز" (Your friend gets 15% off their first booking)
  - Icon + text: "أنت تحصل على 20 ر.س رصيد" (You get 20 SAR credit)
- Credit balance card:
  - "رصيدك الحالي: ١٩.٥٠ ر.س" with expiry date
- Friends invited count: "دعوت ٣ أصدقاء حتى الآن ✓"

### New Screen: Enter Referral Code (during signup flow)
On the OTP verification success screen (or the profile completion screen post-OTP), add an optional input:
- "هل لديك كود دعوة؟" (Do you have a referral code?) — expandable/collapsible
- Text field with submit button
- On success: toast "تم تطبيق الخصم! ستحصل على 15% خصم في حجزك الأول" (Discount applied! You'll get 15% off your first booking)
- On error: inline error message per error code

### Update: Booking Checkout Screen
If credit balance > 0 OR a referee discount applies, show a breakdown:
```
المجموع الأصلي:       ١٢٠.٠٠ ر.س
خصم الدعوة (١٥٪):   -١٨.٠٠ ر.س
رصيد المحفظة:        -٢٠.٠٠ ر.س
─────────────────────────────────
الإجمالي المستحق:     ٨٢.٠٠ ر.س
```
Green badge: "تم تطبيق خصم الدعوة" if referral discount is active.

### State Management

New Riverpod provider: `lib/features/referral/presentation/referral_provider.dart`
```dart
@riverpod
class ReferralNotifier extends _$ReferralNotifier {
  @override
  Future<ReferralState> build() => _load();

  Future<void> applyCode(String code) async { ... }
  Future<void> shareCode() async { ... } // uses share_plus package
}
```

New repository: `lib/features/referral/data/referral_repository.dart`
Maps to the two API endpoints above.

---

## Notifications

When a referral is completed (referrer credit awarded):
- Push notification to referrer: "🎉 صديقك أكمل أول حجز! تم إضافة 20 ر.س لرصيدك"
- In-app: update credit balance on next app resume (re-fetch profile)

Fire via the existing `Notifications` module — use the `SendPushNotificationCommand` pattern already in place.

---

## Edge Cases & Validation

- Referral code input is case-insensitive on the backend (normalize to uppercase)
- If credit balance is less than booking total, only partial credit is applied — customer pays the remainder via card
- Credit cannot be cashed out — platform credit only
- If a referred customer requests a refund on their first booking (dispute resolved in their favour), the referrer credit is NOT rolled back in V1 (log only, handle manually)
- Deep link `https://khudmati.app/join?ref=KHUD1A2B` should pre-fill the referral code field on signup — implement as a GoRouter redirect parameter
- Credit rows must be consumed oldest-expiry-first

---

## Out of Scope (do not implement)
- Admin referral analytics dashboard (future)
- Multi-tier referrals (A refers B who refers C)
- Referral codes for providers
- Cash withdrawal of credits
- Referral code on the web landing page
- Promo codes (separate feature)

---

## File Locations

| File | Purpose |
|---|---|
| `Modules/Customers/Application/Commands/ApplyReferralCodeCommand.cs` | Apply code command + handler |
| `Modules/Customers/Application/Queries/GetReferralInfoQuery.cs` | Fetch referral code + credit balance |
| `Khudmati.API/Controllers/CustomersController.cs` | Add two new endpoints |
| `Khudmati.API/EventHandlers/ReferralAwardHandler.cs` | Listen for PaymentReleased, award referrer credit |
| `lib/features/referral/presentation/referral_screen.dart` | Referral screen |
| `lib/features/referral/presentation/referral_provider.dart` | Riverpod state |
| `lib/features/referral/data/referral_repository.dart` | API calls |

---

## Acceptance Criteria
- [ ] Every new customer receives a unique 8-character referral code automatically on registration
- [ ] A customer can apply a referral code exactly once; subsequent attempts return `REFERRAL_ALREADY_USED`
- [ ] Self-referral is rejected with `REFERRAL_SELF_REFERRAL`
- [ ] The referee's first booking shows a 15% discount at checkout
- [ ] The referrer receives 20 SAR credit after the referee's first booking reaches `Paid` status
- [ ] Credit is auto-applied at checkout, reducing the Stripe charge
- [ ] The Referral Screen shows the current code, credit balance, and share button
- [ ] All UI text is in Arabic; layout is RTL
- [ ] Deep link pre-fills the referral code at signup
