-- The sale table has a total_amount column from the original schema before migration 006
-- was updated to use subtotal/tax/total. The application code does not write total_amount,
-- so give it a default of 0 to avoid NOT NULL violations on INSERT.
-- Guarded: on a fresh build the current 006 creates sale with subtotal/tax/total and no
-- total_amount column, so only alter it where the legacy column actually exists.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale' AND column_name = 'total_amount'
    ) THEN
        ALTER TABLE sale ALTER COLUMN total_amount SET DEFAULT 0;
    END IF;
END $$;
