-- Super Admin Tables Migration
-- Run this against your PostgreSQL database after deploying the new code.
-- These tables are also created automatically via EnsureCreatedAsync on a fresh DB.

-- Platform configuration (single-row config table)
CREATE TABLE IF NOT EXISTS admins.platform_config (
    id                          SERIAL      PRIMARY KEY,
    commission_rate             INT         NOT NULL DEFAULT 15,
    job_timeout_minutes         INT         NOT NULL DEFAULT 2,
    max_providers_per_area      INT         NOT NULL DEFAULT 10,
    min_rating_to_remain        INT         NOT NULL DEFAULT 50,
    auto_refund_threshold_days  INT         NOT NULL DEFAULT 1,
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by_admin_id         UUID        REFERENCES admins.accounts(id)
);

-- Audit log
CREATE TABLE IF NOT EXISTS admins.audit_log (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID        NOT NULL REFERENCES admins.accounts(id),
    action_type TEXT        NOT NULL,
    description TEXT        NOT NULL,
    target_type TEXT,
    target_id   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_audit_log_admin_id   ON admins.audit_log (admin_id);
CREATE INDEX IF NOT EXISTS ix_audit_log_created_at ON admins.audit_log (created_at DESC);
