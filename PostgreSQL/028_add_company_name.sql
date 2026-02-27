-- EPIC-0-007: Add company_name (from registration) to company table
-- Company name is entered at registration and displayed/prepopulated in profile

ALTER TABLE company ADD COLUMN IF NOT EXISTS company_name TEXT;
COMMENT ON COLUMN company.company_name IS 'Company/business name entered at registration. Used to prepopulate store profile.';

-- Update company_create to accept and store company_name
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT);

CREATE OR REPLACE FUNCTION company_create(
    p_email TEXT,
    p_status TEXT,
    p_trial_start_date TIMESTAMPTZ,
    p_trial_end_date TIMESTAMPTZ,
    p_subscription_tier TEXT,
    p_created_date TIMESTAMPTZ,
    p_verification_token TEXT DEFAULT NULL,
    p_verification_token_expires TIMESTAMPTZ DEFAULT NULL,
    p_last_modified_date TIMESTAMPTZ DEFAULT NULL,
    p_password_hash TEXT DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO company (
        email, status, trial_start_date, trial_end_date,
        verification_token, verification_token_expires, subscription_tier,
        created_date, last_modified_date, password_hash, company_name
    )
    VALUES (
        p_email, p_status, p_trial_start_date, p_trial_end_date,
        p_verification_token, p_verification_token_expires, p_subscription_tier,
        p_created_date, p_last_modified_date, p_password_hash, p_company_name
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT) IS 'Creates a company with optional company name from registration.';
