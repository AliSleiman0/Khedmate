-- Migration: create bookings.disputes table
-- Feature: Admin Disputes (prompt 13)
-- Run once against the Postgres DB.

CREATE TABLE IF NOT EXISTS bookings.disputes (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id               UUID        NOT NULL REFERENCES bookings.jobs(id),
    customer_id          UUID        NOT NULL,
    provider_id          UUID        NOT NULL,
    complaint            TEXT        NOT NULL,
    admin_note           TEXT        NULL,
    status               VARCHAR(20) NOT NULL DEFAULT 'Open',
    resolved_at          TIMESTAMPTZ NULL,
    resolved_by_admin_id UUID        NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS ix_disputes_job_id ON bookings.disputes(job_id);
CREATE INDEX IF NOT EXISTS ix_disputes_status  ON bookings.disputes(status);
