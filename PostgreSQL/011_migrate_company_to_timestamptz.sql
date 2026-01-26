-- Migrate company table from TIMESTAMP to TIMESTAMPTZ
-- This migration converts all TIMESTAMP columns to TIMESTAMPTZ for timezone awareness

-- Alter trial_start_date
ALTER TABLE company 
ALTER COLUMN trial_start_date TYPE TIMESTAMPTZ USING trial_start_date AT TIME ZONE 'UTC';

-- Alter trial_end_date
ALTER TABLE company 
ALTER COLUMN trial_end_date TYPE TIMESTAMPTZ USING trial_end_date AT TIME ZONE 'UTC';

-- Alter verification_token_expires
ALTER TABLE company 
ALTER COLUMN verification_token_expires TYPE TIMESTAMPTZ USING verification_token_expires AT TIME ZONE 'UTC';

-- Alter created_date
ALTER TABLE company 
ALTER COLUMN created_date TYPE TIMESTAMPTZ USING created_date AT TIME ZONE 'UTC';

-- Alter last_modified_date
ALTER TABLE company 
ALTER COLUMN last_modified_date TYPE TIMESTAMPTZ USING last_modified_date AT TIME ZONE 'UTC';

-- Verify changes
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'company' 
  AND column_name IN ('trial_start_date', 'trial_end_date', 'verification_token_expires', 'created_date', 'last_modified_date')
ORDER BY column_name;
