-- Migration: Add director_review_type to distinguish Scenario 1 (Initial Review) from Scenario 2 (Final Decision)
-- Date: 2026-07-16
-- Note: MySQL 8.0 does not support ADD COLUMN IF NOT EXISTS; run only once.

ALTER TABLE applications
    ADD COLUMN director_review_type ENUM('INITIAL', 'FINAL') NULL
    AFTER status;
