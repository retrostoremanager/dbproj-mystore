-- Migrate company table VARCHAR columns to TEXT
-- This ensures exact type matching with function return types

-- Alter email column
ALTER TABLE company 
ALTER COLUMN email TYPE TEXT;

-- Alter status column
ALTER TABLE company 
ALTER COLUMN status TYPE TEXT;

-- Alter verification_token column
ALTER TABLE company 
ALTER COLUMN verification_token TYPE TEXT;

-- Alter subscription_tier column
ALTER TABLE company 
ALTER COLUMN subscription_tier TYPE TEXT;

-- Verify changes
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'company' 
  AND column_name IN ('email', 'status', 'verification_token', 'subscription_tier')
ORDER BY column_name;
