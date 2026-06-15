-- Issue #357: Consignment DB schema retry — align ConsignmentItems / ConsignmentPayouts
-- with the acceptance criteria. Builds on 045_create_consignment_tables.sql and
-- 057_align_consignment_schema.sql. Idempotent and safe to re-run.
--
-- Acceptance criteria addressed by this migration:
--   1. status has DEFAULT 'active'
--   2. updated_at is NOT NULL (default NOW() to backfill any pre-existing rows)
--   3. All foreign keys reference parent tables with ON DELETE NO ACTION
--   4. Indexes named ix_consignment_items_company on (company_id)
--      and ix_consignment_payouts_item on (consignment_item_id)
--
-- Notes:
--   * The physical table names remain consignment_item / consignment_payout (singular,
--     matching the existing PostgreSQL naming convention in this project). The AC's
--     PascalCase plural names describe the logical entities.
--   * ON DELETE NO ACTION is the PostgreSQL default referential action and is functionally
--     equivalent to RESTRICT for non-deferrable constraints; we set it explicitly to satisfy
--     the AC and to override the prior RESTRICT / CASCADE choices from migration 057.

-- 1. status DEFAULT 'active'
ALTER TABLE consignment_item
    ALTER COLUMN status SET DEFAULT 'active';

-- 2. updated_at NOT NULL (with default to backfill any historical NULLs)
UPDATE consignment_item SET updated_at = COALESCE(updated_at, created_at, NOW())
    WHERE updated_at IS NULL;

ALTER TABLE consignment_item
    ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE consignment_item
    ALTER COLUMN updated_at SET NOT NULL;

-- 3. Foreign keys: ON DELETE NO ACTION
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_company;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE NO ACTION;

ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_customer;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_customer
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE NO ACTION;

ALTER TABLE consignment_payout DROP CONSTRAINT IF EXISTS fk_consignment_payout_item;
ALTER TABLE consignment_payout
    ADD CONSTRAINT fk_consignment_payout_item
    FOREIGN KEY (consignment_item_id) REFERENCES consignment_item(id) ON DELETE NO ACTION;

-- 4. Indexes with the names required by the acceptance criteria.
--    Drop the prior-name indexes so we don't carry two indexes for the same column.
DROP INDEX IF EXISTS ix_consignment_item_company_id;
CREATE INDEX IF NOT EXISTS ix_consignment_items_company
    ON consignment_item(company_id);

DROP INDEX IF EXISTS ix_consignment_payout_item_id;
CREATE INDEX IF NOT EXISTS ix_consignment_payouts_item
    ON consignment_payout(consignment_item_id);
