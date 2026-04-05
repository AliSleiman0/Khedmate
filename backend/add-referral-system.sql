-- ============================================================
-- Feature #17: Referral System
-- Run once against the PostgreSQL database.
-- ============================================================

-- Referral codes: one code per customer, auto-generated on registration
CREATE TABLE IF NOT EXISTS customers.referral_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.accounts(id) ON DELETE CASCADE,
    code        VARCHAR(10) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_referral_codes_customer ON customers.referral_codes(customer_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON customers.referral_codes(code);

-- Referral uses: tracks the referrer → referee relationship
-- Status: Pending | Completed
CREATE TABLE IF NOT EXISTS customers.referral_uses (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_customer_id   UUID NOT NULL REFERENCES customers.accounts(id),
    referred_customer_id   UUID NOT NULL REFERENCES customers.accounts(id),
    qualifying_booking_id  UUID REFERENCES bookings.jobs(id),
    referrer_credit_amount NUMERIC(10,2) NOT NULL,
    referee_discount_pct   NUMERIC(5,2)  NOT NULL,
    status                 VARCHAR(20)   NOT NULL DEFAULT 'Pending',
    created_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
    completed_at           TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_referral_uses_referred ON customers.referral_uses(referred_customer_id);
CREATE INDEX IF NOT EXISTS idx_referral_uses_referrer ON customers.referral_uses(referrer_customer_id);
CREATE INDEX IF NOT EXISTS idx_referral_uses_status ON customers.referral_uses(status);

-- Customer credits: platform credit wallet
-- source_type: Referral | Promo | Refund
CREATE TABLE IF NOT EXISTS customers.customer_credits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers.accounts(id) ON DELETE CASCADE,
    amount      NUMERIC(10,2) NOT NULL,
    source_type VARCHAR(30)   NOT NULL,
    source_id   UUID,
    expires_at  TIMESTAMPTZ   NOT NULL,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    used_at     TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_customer_credits_customer ON customers.customer_credits(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_credits_expires ON customers.customer_credits(expires_at);

-- Add referral_discount_amount to bookings.jobs for recording applied discount
ALTER TABLE bookings.jobs
    ADD COLUMN IF NOT EXISTS referral_discount_amount NUMERIC(10,2);

-- Add credit_applied_amount to payments.transactions for recording applied credit
ALTER TABLE payments.transactions
    ADD COLUMN IF NOT EXISTS credit_applied_amount NUMERIC(10,2);
