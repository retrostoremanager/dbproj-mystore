-- Issue #360 (orchestrator-mystore): Promotions DB schema retry — Promotions table migration applying cleanly
-- Follow-up to 055_create_promotion_table.sql and 060_align_promotion_schema.sql.
--
-- Goals:
--   1. Ensure the promotion table exists (idempotent CREATE TABLE IF NOT EXISTS) with the
--      exact column names, types, nullability, and defaults expected by PromotionRepository.
--   2. Add any missing columns / constraints / defaults on databases that already have an
--      older shape of the table (defensive ALTER ... IF NOT EXISTS / ADD CONSTRAINT IF NOT
--      EXISTS-equivalent blocks).
--   3. Ensure both required indexes exist:
--        - ix_promotion_company           (company_id)
--        - ix_promotion_company_active_dates (company_id, is_active, start_date, end_date)
--   4. Safe to apply on a clean database AND on a database where the table already exists.

-- 1. Create the table if it is missing. Mirrors 055 with the canonical column set used by
--    PromotionRepository (see MyStore.Repositories/PromotionRepository.cs SelectColumns).
CREATE TABLE IF NOT EXISTS promotion (
    id               SERIAL PRIMARY KEY,
    company_id       INTEGER NOT NULL,
    name             VARCHAR(200) NOT NULL,
    type             VARCHAR(20) NOT NULL,
    discount_percent DECIMAL(5, 2),
    buy_quantity     INTEGER,
    get_quantity     INTEGER,
    scope            VARCHAR(20) NOT NULL DEFAULT 'store_wide',
    scope_value      VARCHAR(200),
    start_date       TIMESTAMPTZ NOT NULL,
    end_date         TIMESTAMPTZ,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_by       INTEGER NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Defensive column adds for databases where the table existed in an earlier shape.
--    Postgres 9.6+ supports ADD COLUMN IF NOT EXISTS, so each ALTER is safely idempotent.
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS company_id       INTEGER;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS name             VARCHAR(200);
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS type             VARCHAR(20);
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS discount_percent DECIMAL(5, 2);
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS buy_quantity     INTEGER;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS get_quantity     INTEGER;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS scope            VARCHAR(20);
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS scope_value      VARCHAR(200);
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS start_date       TIMESTAMPTZ;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS end_date         TIMESTAMPTZ;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS is_active        BOOLEAN;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS created_by       INTEGER;
ALTER TABLE promotion ADD COLUMN IF NOT EXISTS created_at       TIMESTAMPTZ;

-- 3. Re-assert defaults so NOT NULL constraints below don't fail on backfill.
ALTER TABLE promotion ALTER COLUMN scope      SET DEFAULT 'store_wide';
ALTER TABLE promotion ALTER COLUMN is_active  SET DEFAULT TRUE;
ALTER TABLE promotion ALTER COLUMN created_at SET DEFAULT NOW();

-- 4. Re-assert NOT NULL on the columns that PromotionRepository.GetActiveAsync relies on
--    (is_active, start_date) plus the other required columns. These are no-ops if already
--    NOT NULL; on a freshly-created table all values are populated so the ALTERs succeed.
ALTER TABLE promotion ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN name       SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN type       SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN scope      SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN start_date SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN is_active  SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN created_by SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN created_at SET NOT NULL;

-- 5. Re-create FK + CHECK constraints idempotently. DROP IF EXISTS first so re-runs are safe.
ALTER TABLE promotion DROP CONSTRAINT IF EXISTS fk_promotion_company;
ALTER TABLE promotion
    ADD CONSTRAINT fk_promotion_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE;

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS fk_promotion_created_by;
ALTER TABLE promotion
    ADD CONSTRAINT fk_promotion_created_by
    FOREIGN KEY (created_by) REFERENCES "user"(id);

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS chk_promotion_type;
ALTER TABLE promotion
    ADD CONSTRAINT chk_promotion_type
    CHECK (type IN ('percentage', 'bxgy'));

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS chk_promotion_scope;
ALTER TABLE promotion
    ADD CONSTRAINT chk_promotion_scope
    CHECK (scope IN ('store_wide', 'category', 'item'));

-- 6. Indexes. Both the dedicated company_id index (from 060) and the composite active-dates
--    index (from 055) are required by the acceptance criteria. CREATE INDEX IF NOT EXISTS
--    makes both safe to re-run.
CREATE INDEX IF NOT EXISTS ix_promotion_company_id
    ON promotion(company_id);

CREATE INDEX IF NOT EXISTS ix_promotion_company_active_dates
    ON promotion(company_id, is_active, start_date, end_date);
