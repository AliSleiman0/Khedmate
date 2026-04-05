-- Migration: add photo_type to bookings.job_photos
-- Feature: Post-Job Photo Requirement (prompt 11)
-- ALL existing rows (customer before-photos) are backfilled with 'before'.

ALTER TABLE bookings.job_photos
    ADD COLUMN photo_type TEXT NOT NULL DEFAULT 'before'
        CHECK (photo_type IN ('before', 'after'));
