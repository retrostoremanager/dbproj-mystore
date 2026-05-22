-- Add total_price to sale_item if it was missing from the original CREATE TABLE.
-- Migration 007 was edited after initial deploy; CREATE TABLE IF NOT EXISTS
-- silently skipped the new column on existing databases.
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS total_price DECIMAL(18, 2) NOT NULL DEFAULT 0;
