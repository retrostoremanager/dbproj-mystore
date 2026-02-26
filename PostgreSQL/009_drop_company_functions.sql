-- Drop existing company functions before recreating them
-- This ensures functions are recreated with correct signatures

-- Drop company_get_by_id (all variations)
DROP FUNCTION IF EXISTS company_get_by_id(INTEGER);

-- Drop company_get_by_email (all variations)
DROP FUNCTION IF EXISTS company_get_by_email(VARCHAR);
DROP FUNCTION IF EXISTS company_get_by_email(TEXT);

-- Drop company_get_by_verification_token (all variations)
DROP FUNCTION IF EXISTS company_get_by_verification_token(VARCHAR);
DROP FUNCTION IF EXISTS company_get_by_verification_token(TEXT);

-- Drop company_get_by_password_reset_token (all variations)
DROP FUNCTION IF EXISTS company_get_by_password_reset_token(VARCHAR);
DROP FUNCTION IF EXISTS company_get_by_password_reset_token(TEXT);

-- Drop company_create (all variations with different parameter orders and types)
DROP FUNCTION IF EXISTS company_create(VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR, TIMESTAMP, VARCHAR, TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS company_create(VARCHAR, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMP, TIMESTAMP, TEXT, TIMESTAMP, TEXT, TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT);

-- Drop company_update (all variations with different parameter orders and types)
DROP FUNCTION IF EXISTS company_update(INTEGER, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR, TIMESTAMP, VARCHAR, TIMESTAMP);
DROP FUNCTION IF EXISTS company_update(INTEGER, VARCHAR, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS company_update(INTEGER, TEXT, TEXT, TIMESTAMP, TIMESTAMP, TEXT, TIMESTAMP, TEXT, TIMESTAMP);
DROP FUNCTION IF EXISTS company_update(INTEGER, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ);
-- Drop company_update with password reset params (EPIC-0-003)
DROP FUNCTION IF EXISTS company_update(INTEGER, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, TIMESTAMPTZ, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ);

-- Drop company_update_stripe_customer_id (EPIC-0-004)
DROP FUNCTION IF EXISTS company_update_stripe_customer_id(INTEGER, TEXT);

SELECT 'Old company functions dropped successfully!' AS status;
