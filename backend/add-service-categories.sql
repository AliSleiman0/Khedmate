-- ============================================================
-- Admin-managed service categories
-- Run once against the PostgreSQL database. Idempotent — safe to
-- re-run on every deploy.
--
-- Column names are PascalCase + double-quoted to match the EF
-- model config in Program.cs (no snake_case naming convention is
-- registered for this entity, so EF maps property names verbatim).
-- ============================================================

CREATE TABLE IF NOT EXISTS bookings.categories (
    "Id"                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    "Slug"               VARCHAR(50)  NOT NULL,
    "NameEn"             VARCHAR(100) NOT NULL,
    "NameAr"             VARCHAR(100) NOT NULL,
    "IconKey"            VARCHAR(50)  NOT NULL DEFAULT 'category',
    "IconUrl"            TEXT,
    "DisplayOrder"       INT          NOT NULL DEFAULT 100,
    "IsActive"           BOOLEAN      NOT NULL DEFAULT TRUE,
    "RequiresSkillTest"  BOOLEAN      NOT NULL DEFAULT TRUE,
    "CreatedAt"          TIMESTAMP    NOT NULL DEFAULT now(),
    "UpdatedAt"          TIMESTAMP    NOT NULL DEFAULT now(),
    "CreatedBy"          UUID
);

CREATE UNIQUE INDEX IF NOT EXISTS ix_categories_slug
    ON bookings.categories ("Slug");

CREATE INDEX IF NOT EXISTS ix_categories_active_order
    ON bookings.categories ("IsActive", "DisplayOrder");

-- ── Seed the 7 baseline categories ──────────────────────────
-- Idempotent via ON CONFLICT — admin edits to NameEn/NameAr/IconKey
-- on subsequent boots are preserved.
INSERT INTO bookings.categories
  ("Id", "Slug", "NameEn", "NameAr", "IconKey", "DisplayOrder",
   "IsActive", "RequiresSkillTest", "CreatedAt", "UpdatedAt")
VALUES
  (gen_random_uuid(), 'plumbing',       'Plumbing',       'السباكة',        'plumbing',          10, TRUE, TRUE,  now(), now()),
  (gen_random_uuid(), 'electrical',     'Electrical',     'الكهرباء',       'electric_bolt',     20, TRUE, TRUE,  now(), now()),
  (gen_random_uuid(), 'cleaning',       'Cleaning',       'التنظيف',        'cleaning_services', 30, TRUE, TRUE,  now(), now()),
  (gen_random_uuid(), 'carpentry',      'Carpentry',      'النجارة',        'handyman',          40, TRUE, TRUE,  now(), now()),
  (gen_random_uuid(), 'painting',       'Painting',       'الدهان',         'format_paint',      50, TRUE, TRUE,  now(), now()),
  (gen_random_uuid(), 'ac_maintenance', 'AC Maintenance', 'صيانة المكيفات', 'ac_unit',           60, TRUE, FALSE, now(), now()),
  (gen_random_uuid(), 'moving',         'Moving',         'النقل',          'local_shipping',    70, TRUE, FALSE, now(), now())
ON CONFLICT ("Slug") DO NOTHING;
