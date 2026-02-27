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

-- Update company_get_profile to return company_name
CREATE OR REPLACE FUNCTION company_get_profile(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    company_name TEXT,
    store_name TEXT,
    store_type TEXT,
    store_address TEXT,
    store_city TEXT,
    store_state TEXT,
    store_zip_code TEXT,
    store_phone TEXT,
    timezone TEXT,
    locale TEXT,
    logo_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.company_name, c.store_name, c.store_type, c.store_address, c.store_city, c.store_state,
           c.store_zip_code, c.store_phone, c.timezone, c.locale, c.logo_url
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Update company_update_profile to accept company_name
CREATE OR REPLACE FUNCTION company_update_profile(
    p_id INTEGER,
    p_company_name TEXT DEFAULT NULL,
    p_store_name TEXT DEFAULT NULL,
    p_store_type TEXT DEFAULT NULL,
    p_store_address TEXT DEFAULT NULL,
    p_store_city TEXT DEFAULT NULL,
    p_store_state TEXT DEFAULT NULL,
    p_store_zip_code TEXT DEFAULT NULL,
    p_store_phone TEXT DEFAULT NULL,
    p_timezone TEXT DEFAULT NULL,
    p_locale TEXT DEFAULT NULL,
    p_logo_url TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET company_name = COALESCE(p_company_name, company_name),
        store_name = COALESCE(p_store_name, store_name),
        store_type = COALESCE(p_store_type, store_type),
        store_address = COALESCE(p_store_address, store_address),
        store_city = COALESCE(p_store_city, store_city),
        store_state = COALESCE(p_store_state, store_state),
        store_zip_code = COALESCE(p_store_zip_code, store_zip_code),
        store_phone = COALESCE(p_store_phone, store_phone),
        timezone = COALESCE(p_timezone, timezone),
        locale = COALESCE(p_locale, locale),
        logo_url = COALESCE(p_logo_url, logo_url),
        last_modified_date = NOW()
    WHERE id = p_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION company_get_profile(INTEGER) IS 'Returns company profile including company name from registration.';
COMMENT ON FUNCTION company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates company profile fields including company name.';
