-- Issue #373: Consignment DB schema retry — ConsignmentItems and ConsignmentPayouts
-- tables with FK constraints and indexes. Supersedes issues #272 (057) and #357 (063).
--
-- This migration is fully idempotent: it applies cleanly on a fresh database
-- (where 045/057/063 have not run) and on an existing database (where any subset
-- of them has). It asserts the final desired schema state described in the AC.
--
-- Acceptance criteria addressed:
--   * consignment_item (logical: ConsignmentItems) with the required columns,
--     types, NOT NULLs, defaults, and CHECK constraints
--       - status CHECK IN ('active','sold','returned'), DEFAULT 'active'
--       - split_percent CHECK between 0 and 100
--       - created_at / updated_at NOT NULL DEFAULT NOW()
--   * consignment_payout (logical: ConsignmentPayouts) with FK to consignment_item
--     using ON DELETE CASCADE (payouts are owned by their consignment item)
--   * Index on consignment_item(company_id) for tenant-scoped queries
--   * Index on consignment_item(customer_id) for customer lookups
--   * Idempotent via IF NOT EXISTS guards and conditional ALTERs
--
-- Notes on naming:
--   The acceptance criteria use SQL Server-style PascalCase names
--   (ConsignmentItems, ConsignmentPayouts) and types (nvarchar, datetime2,
--   GETUTCDATE()). This project targets PostgreSQL with snake_case singular
--   table names (consignment_item, consignment_payout); the logical entities
--   and column semantics are equivalent.

-- =============================================================================
-- 1. consignment_item table
-- =============================================================================
CREATE TABLE IF NOT EXISTS consignment_item (
    id              SERIAL PRIMARY KEY,
    company_id      INTEGER        NOT NULL,
    customer_id     INTEGER        NOT NULL,
    description     VARCHAR(500)   NOT NULL,
    asking_price    DECIMAL(18, 2) NOT NULL,
    sale_price      DECIMAL(18, 2),
    split_percent   DECIMAL(5, 2)  NOT NULL,
    status          VARCHAR(50)    NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- Backfill updated_at for any rows from earlier migrations where it was nullable.
UPDATE consignment_item
   SET updated_at = COALESCE(updated_at, created_at, NOW())
 WHERE updated_at IS NULL;

-- Ensure status / updated_at defaults and NOT NULLs are in place on pre-existing tables.
ALTER TABLE consignment_item ALTER COLUMN status      SET DEFAULT 'active';
ALTER TABLE consignment_item ALTER COLUMN updated_at  SET DEFAULT NOW();
ALTER TABLE consignment_item ALTER COLUMN updated_at  SET NOT NULL;

-- Normalise any legacy status values to the canonical set.
UPDATE consignment_item SET status = 'active'   WHERE status = 'pending';
UPDATE consignment_item SET status = 'returned' WHERE status = 'cancelled';

-- =============================================================================
-- 2. consignment_item CHECK constraints (drop-and-add for idempotency)
-- =============================================================================
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS chk_consignment_item_status;
ALTER TABLE consignment_item
    ADD CONSTRAINT chk_consignment_item_status
    CHECK (status IN ('active', 'sold', 'returned'));

ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS chk_consignment_item_asking_price;
ALTER TABLE consignment_item
    ADD CONSTRAINT chk_consignment_item_asking_price
    CHECK (asking_price >= 0);

ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS chk_consignment_item_sale_price;
ALTER TABLE consignment_item
    ADD CONSTRAINT chk_consignment_item_sale_price
    CHECK (sale_price IS NULL OR sale_price >= 0);

ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS chk_consignment_item_split_percent;
ALTER TABLE consignment_item
    ADD CONSTRAINT chk_consignment_item_split_percent
    CHECK (split_percent >= 0 AND split_percent <= 100);

-- =============================================================================
-- 3. consignment_item FK constraints
-- =============================================================================
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_company;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE NO ACTION;

ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_customer;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_customer
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE NO ACTION;

-- =============================================================================
-- 4. consignment_item indexes
-- =============================================================================
-- Tenant-scoped queries
CREATE INDEX IF NOT EXISTS ix_consignment_items_company
    ON consignment_item(company_id);

-- Customer lookups
CREATE INDEX IF NOT EXISTS ix_consignment_items_customer
    ON consignment_item(customer_id);

COMMENT ON TABLE consignment_item IS
    'ConsignmentItems: items accepted from customers to sell on consignment.';

-- =============================================================================
-- 5. consignment_payout table
-- =============================================================================
CREATE TABLE IF NOT EXISTS consignment_payout (
    id                      SERIAL PRIMARY KEY,
    consignment_item_id     INTEGER        NOT NULL,
    amount                  DECIMAL(18, 2) NOT NULL,
    paid_at                 TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    notes                   VARCHAR(500)
);

-- If an earlier migration created notes as TEXT, narrow it to VARCHAR(500)
-- to match the acceptance criteria. Cast is safe because TEXT and VARCHAR
-- share storage; rows longer than 500 chars (none expected) would fail.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'consignment_payout'
           AND column_name = 'notes'
           AND data_type   = 'text'
    ) THEN
        ALTER TABLE consignment_payout
            ALTER COLUMN notes TYPE VARCHAR(500);
    END IF;
END $$;

ALTER TABLE consignment_payout ALTER COLUMN paid_at SET DEFAULT NOW();

-- =============================================================================
-- 6. consignment_payout CHECK / FK constraints
-- =============================================================================
ALTER TABLE consignment_payout DROP CONSTRAINT IF EXISTS chk_consignment_payout_amount;
ALTER TABLE consignment_payout
    ADD CONSTRAINT chk_consignment_payout_amount
    CHECK (amount >= 0);

-- Payouts are owned by their consignment item: deleting the parent cascades.
ALTER TABLE consignment_payout DROP CONSTRAINT IF EXISTS fk_consignment_payout_item;
ALTER TABLE consignment_payout
    ADD CONSTRAINT fk_consignment_payout_item
    FOREIGN KEY (consignment_item_id) REFERENCES consignment_item(id) ON DELETE CASCADE;

-- =============================================================================
-- 7. consignment_payout indexes
-- =============================================================================
CREATE INDEX IF NOT EXISTS ix_consignment_payouts_item
    ON consignment_payout(consignment_item_id);

COMMENT ON TABLE consignment_payout IS
    'ConsignmentPayouts: payouts to customers for their share of consignment sales.';
