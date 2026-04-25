-- ============================================================
-- Landing-page contact form submissions (Feature #16)
-- Run once against the production PostgreSQL database. Idempotent —
-- safe to re-run on every deploy.
--
-- Column names are PascalCase + double-quoted to match the EF
-- model config in Program.cs (no snake_case naming convention is
-- registered for ContactInquiry, so EF maps property names verbatim).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.contact_inquiries (
    "Id"           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    "Name"         VARCHAR(200) NOT NULL,
    "Email"        VARCHAR(200) NOT NULL,
    "Message"      TEXT         NOT NULL,
    "SubmittedAt"  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_contact_inquiries_submitted_at
    ON public.contact_inquiries ("SubmittedAt" DESC);
