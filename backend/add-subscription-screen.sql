-- Feature #26: Provider subscription screen — add missing columns to provider_subscriptions
-- Run against PostgreSQL before deploying the updated backend.

ALTER TABLE providers.provider_subscriptions
    ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS cancels_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Create unique index on stripe_subscription_id (partial)
CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_subscriptions_stripe_sub_id
    ON providers.provider_subscriptions(stripe_subscription_id)
    WHERE stripe_subscription_id IS NOT NULL;
