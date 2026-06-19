-- Issue #374 (orchestrator-mystore): Promotions DB schema retry — Promotions table migration
-- applying cleanly with correct column types and indexes.
--
-- Supersedes:
--   - 055_create_promotion_table.sql            (original create)
--   - 060_align_promotion_schema.sql            (single-column company_id index)
--   - 064_align_promotion_schema_retry.sql      (defensive realignment; issues #312, #360)
--
-- Goals (acceptance criteria for #374):
--   1. promotion table exists with the exact column set, types, nullability, defaults, and
--      constraints described in #374.
--   2. Indexes:
--        - ix_promotion_company_active_dates (company_id, is_active, start_date, end_date)
--        - ix_promotion_company_id           (company_id)             -- preserved from #312
--   3. Cross-column CHECK constraints enforcing the type ↔ required-columns relationship:
--        - type = 'percentage' ⇒ discount_percent IS NOT NULL
--        - type = 'bxgy'       ⇒ buy_quantity IS NOT NULL AND get_quantity IS NOT NULL
--   4. Migration is idempotent and applies cleanly on a fresh database AND on a database
--      that already has the promotion table from a previous migration.
--
-- Notes:
--   - This project is PostgreSQL. The acceptance criteria text in #374 references SQL
--     Server-style types (nvarchar, datetime2, bit, GETUTCDATE, IDENTITY). The PostgreSQL
--     equivalents are used here and are consistent with every prior migration in this
--     project: SERIAL (IDENTITY), VARCHAR (nvarchar), TIMESTAMPTZ (datetime2), BOOLEAN
--     (bit), NOW() (GETUTCDATE).
--   - created_by is made nullable per the #374 acceptance criteria, with ON DELETE SET
--     NULL so that deleting a user does not cascade-delete their historical promotions.
--   - The cross-column CHECK constraint is enforced at the database level (see
--     chk_promotion_type_columns below). It is also re-enforced at the application layer
--     in PromotionService for friendlier error messages.

-- =============================================================================
-- 1. Create the table if missing. Mirrors the canonical column set used by
--    PromotionRepository (see MyStore.Repositories/PromotionRepository.cs).
-- =============================================================================
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
    created_by       INTEGER,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 2. Defensive column adds for databases where the table existed in an earlier
--    shape. PostgreSQL 9.6+ supports ADD COLUMN IF NOT EXISTS.
-- =============================================================================
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

-- =============================================================================
-- 3. Re-assert defaults so NOT NULL constraints below don't fail on backfill.
-- =============================================================================
ALTER TABLE promotion ALTER COLUMN scope      SET DEFAULT 'store_wide';
ALTER TABLE promotion ALTER COLUMN is_active  SET DEFAULT TRUE;
ALTER TABLE promotion ALTER COLUMN created_at SET DEFAULT NOW();

-- =============================================================================
-- 4. Re-assert NOT NULL on the required columns. created_by is intentionally
--    nullable per #374; explicitly DROP NOT NULL in case a prior migration set it.
-- =============================================================================
ALTER TABLE promotion ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN name       SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN type       SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN scope      SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN start_date SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN is_active  SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE promotion ALTER COLUMN created_by DROP NOT NULL;

-- =============================================================================
-- 5. Re-create FK + CHECK constraints idempotently. DROP IF EXISTS first so
--    re-runs are safe regardless of prior state.
-- =============================================================================
ALTER TABLE promotion DROP CONSTRAINT IF EXISTS fk_promotion_company;
ALTER TABLE promotion
    ADD CONSTRAINT fk_promotion_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE;

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS fk_promotion_created_by;
ALTER TABLE promotion
    ADD CONSTRAINT fk_promotion_created_by
    FOREIGN KEY (created_by) REFERENCES "user"(id) ON DELETE SET NULL;

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS chk_promotion_type;
ALTER TABLE promotion
    ADD CONSTRAINT chk_promotion_type
    CHECK (type IN ('percentage', 'bxgy'));

ALTER TABLE promotion DROP CONSTRAINT IF EXISTS chk_promotion_scope;
ALTER TABLE promotion
    ADD CONSTRAINT chk_promotion_scope
    CHECK (scope IN ('store_wide', 'category', 'item'));

-- Cross-column CHECK constraint: enforce that the right discount columns are
-- populated for each promotion type. This is the new constraint required by
-- the #374 acceptance criteria.
ALTER TABLE promotion DROP CONSTRAINT IF EXISTS chk_promotion_type_columns;
ALTER TABLE promotion
    ADD CONSTRAINT chk_promotion_type_columns
    CHECK (
        (type = 'percentage' AND discount_percent IS NOT NULL)
        OR
        (type = 'bxgy' AND buy_quantity IS NOT NULL AND get_quantity IS NOT NULL)
    );

-- =============================================================================
-- 6. Indexes. Both indexes are required: the composite active-dates index
--    supports the GetActiveAsync hot path; the dedicated company_id index
--    keeps simple multi-tenant lookups fast.
-- =============================================================================
CREATE INDEX IF NOT EXISTS ix_promotion_company_id
    ON promotion(company_id);

CREATE INDEX IF NOT EXISTS ix_promotion_company_active_dates
    ON promotion(company_id, is_active, start_date, end_date);

-- =============================================================================
-- 7. Documentation comments.
-- =============================================================================
COMMENT ON TABLE  promotion                  IS 'Promotional discounts scoped to store, category, or item with optional date ranges.';
COMMENT ON COLUMN promotion.type             IS 'Promotion type: percentage (discount percent off) or bxgy (buy X get Y free).';
COMMENT ON COLUMN promotion.discount_percent IS 'Percentage discount (0–100). Required when type = percentage.';
COMMENT ON COLUMN promotion.buy_quantity     IS 'Number of items customer must buy. Required when type = bxgy.';
COMMENT ON COLUMN promotion.get_quantity     IS 'Number of items customer gets free. Required when type = bxgy.';
COMMENT ON COLUMN promotion.scope            IS 'Scope of the promotion: store_wide, category, or item.';
COMMENT ON COLUMN promotion.scope_value      IS 'Category name or inventory item id depending on scope. NULL for store_wide.';
COMMENT ON COLUMN promotion.start_date       IS 'Date/time from which the promotion is valid.';
COMMENT ON COLUMN promotion.end_date         IS 'Date/time at which the promotion expires. NULL means no expiry.';
COMMENT ON COLUMN promotion.is_active        IS 'Whether the promotion is currently active.';
COMMENT ON COLUMN promotion.created_by       IS 'User who created the promotion. Nullable so user deletions do not cascade-delete promotions.';
