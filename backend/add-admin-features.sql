-- ============================================================
-- Feature #18 (extension): Provider Subscriptions table
-- Run once against the PostgreSQL database.
-- ============================================================

CREATE TABLE IF NOT EXISTS providers.provider_subscriptions (
    id                      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id             UUID         NOT NULL,
    plan_id                 UUID         NOT NULL REFERENCES providers.subscription_plans(id),
    status                  VARCHAR(20)  NOT NULL DEFAULT 'Active',  -- Active | PastDue | Cancelled | Paused
    stripe_subscription_id  VARCHAR(100),
    current_period_start    TIMESTAMPTZ  NOT NULL,
    current_period_end      TIMESTAMPTZ  NOT NULL,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_provider_subscriptions_provider_id ON providers.provider_subscriptions(provider_id);
CREATE INDEX IF NOT EXISTS idx_provider_subscriptions_status ON providers.provider_subscriptions(status);

-- ============================================================
-- Feature #19: Reminder Rules table
-- Run once against the PostgreSQL database.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.reminder_rules (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    category        VARCHAR(50) NOT NULL UNIQUE,
    interval_days   INT         NOT NULL DEFAULT 90,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ
);
