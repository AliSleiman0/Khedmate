-- Migration: Add unique email index + duplicate check for customers and providers
-- Run this against the live PostgreSQL database before deploying the backend update.
-- Safe to run multiple times (uses IF NOT EXISTS / CREATE INDEX CONCURRENTLY).

-- ── customers.accounts ────────────────────────────────────────────────────────

-- Remove any duplicate emails before adding the unique constraint
-- (keeps the earliest-registered account per email)
DELETE FROM customers.accounts a
USING customers.accounts b
WHERE a."Id" > b."Id"
  AND a."Email" IS NOT NULL
  AND a."Email" = b."Email";

-- Add unique index (partial: only on non-null values)
CREATE UNIQUE INDEX IF NOT EXISTS ix_customers_accounts_email
    ON customers.accounts ("Email")
    WHERE "Email" IS NOT NULL;

-- ── providers.accounts ────────────────────────────────────────────────────────

-- Remove any duplicate emails before adding the unique constraint
DELETE FROM providers.accounts a
USING providers.accounts b
WHERE a."Id" > b."Id"
  AND a."Email" IS NOT NULL
  AND a."Email" = b."Email";

-- Add unique index (partial: only on non-null values)
CREATE UNIQUE INDEX IF NOT EXISTS ix_providers_accounts_email
    ON providers.accounts ("Email")
    WHERE "Email" IS NOT NULL;
