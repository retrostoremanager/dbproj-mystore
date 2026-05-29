-- Migration: make trade_in.payment_type nullable
-- payment_type is only known when a draft is completed (POST /trade-ins/{id}/complete).
-- Drafts do not yet have a payment type, so the column must allow NULL.
-- The check constraint is updated to permit NULL while still restricting non-null values
-- to the two allowed payment types.

ALTER TABLE trade_in
    ALTER COLUMN payment_type DROP NOT NULL;

ALTER TABLE trade_in
    DROP CONSTRAINT IF EXISTS chk_trade_in_payment_type;

ALTER TABLE trade_in
    ADD CONSTRAINT chk_trade_in_payment_type
        CHECK (payment_type IS NULL OR payment_type IN ('cash', 'store_credit'));
