-- ============================================================
-- Feature #18: Subscription Plans (Power Provider)
-- Run once against the PostgreSQL database.
-- ============================================================

CREATE TABLE IF NOT EXISTS providers.subscription_plans (
    id                      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(50)  NOT NULL,
    monthly_fee             NUMERIC(10,2) NOT NULL,
    commission_rate         NUMERIC(5,2) NOT NULL,
    priority_delay_seconds  INT          NOT NULL DEFAULT 30,
    is_active               BOOLEAN      NOT NULL DEFAULT TRUE,
    stripe_price_id         VARCHAR(100),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ
);

-- Seed the PowerProvider plan (99 SAR/month, 10% commission, 30s priority delay)
INSERT INTO providers.subscription_plans (name, monthly_fee, commission_rate, priority_delay_seconds, is_active)
VALUES ('PowerProvider', 99.00, 10.00, 30, TRUE)
ON CONFLICT DO NOTHING;
