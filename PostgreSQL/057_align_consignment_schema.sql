-- Issue #272: Align consignment schema with acceptance criteria
-- 1. Migrate existing status values to the canonical set (active/sold/returned)
-- 2. Replace the status CHECK constraint to enforce only active/sold/returned
-- 3. Add a dedicated company_id index for multi-tenant query performance
-- 4. Recreate FK constraints with explicit ON DELETE behavior
-- This migration is idempotent and safe to run on top of 045_create_consignment_tables.sql.

-- Map legacy status values to the canonical set
UPDATE consignment_item SET status = 'active'   WHERE status = 'pending';
UPDATE consignment_item SET status = 'returned' WHERE status = 'cancelled';

-- Replace the status CHECK constraint
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS chk_consignment_item_status;
ALTER TABLE consignment_item
    ADD CONSTRAINT chk_consignment_item_status
    CHECK (status IN ('active', 'sold', 'returned'));

-- Add a dedicated company_id index for multi-tenant query performance
CREATE INDEX IF NOT EXISTS ix_consignment_item_company_id
    ON consignment_item(company_id);

-- Recreate FK constraints with explicit ON DELETE behavior
-- company_id: RESTRICT (do not allow deleting a company that has consignment items)
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_company;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE RESTRICT;

-- customer_id: RESTRICT (preserve consignment history if a customer is removed)
ALTER TABLE consignment_item DROP CONSTRAINT IF EXISTS fk_consignment_item_customer;
ALTER TABLE consignment_item
    ADD CONSTRAINT fk_consignment_item_customer
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE RESTRICT;

-- consignment_payout.consignment_item_id: CASCADE
-- (payouts are owned by the consignment item and should be removed with it)
ALTER TABLE consignment_payout DROP CONSTRAINT IF EXISTS fk_consignment_payout_item;
ALTER TABLE consignment_payout
    ADD CONSTRAINT fk_consignment_payout_item
    FOREIGN KEY (consignment_item_id) REFERENCES consignment_item(id) ON DELETE CASCADE;
