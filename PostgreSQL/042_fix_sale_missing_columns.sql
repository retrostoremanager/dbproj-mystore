-- Add subtotal, tax, total to sale if they were missing from the original CREATE TABLE.
-- Migration 006 was updated after the table was first deployed, so these columns may not exist
-- on databases created before the edit.
ALTER TABLE sale ADD COLUMN IF NOT EXISTS subtotal DECIMAL(18, 2) NOT NULL DEFAULT 0;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS tax      DECIMAL(18, 2) NOT NULL DEFAULT 0;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS total    DECIMAL(18, 2) NOT NULL DEFAULT 0;
