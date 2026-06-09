-- Issue #312: Align promotion schema with acceptance criteria
-- 1. Add a dedicated company_id index for multi-tenant query performance
-- This migration is idempotent and safe to run on top of 055_create_promotion_table.sql.

-- Add a dedicated single-column company_id index for multi-tenant query performance.
-- The composite index ix_promotion_company_active_dates also covers (company_id) via
-- leftmost-prefix, but a dedicated index makes the multi-tenant intent explicit and
-- guarantees coverage for simple WHERE company_id = ? lookups regardless of planner choice.
CREATE INDEX IF NOT EXISTS ix_promotion_company_id
    ON promotion(company_id);
