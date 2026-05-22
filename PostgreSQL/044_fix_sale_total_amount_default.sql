-- The sale table has a total_amount column from the original schema before migration 006
-- was updated to use subtotal/tax/total. The application code does not write total_amount,
-- so give it a default of 0 to avoid NOT NULL violations on INSERT.
ALTER TABLE sale ALTER COLUMN total_amount SET DEFAULT 0;
