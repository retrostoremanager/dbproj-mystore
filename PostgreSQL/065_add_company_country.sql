-- Issue #380: Add company_country to company profile
-- Adds the column and updates get/update stored procedures to include p_company_country.

ALTER TABLE company ADD COLUMN IF NOT EXISTS company_country TEXT;

COMMENT ON COLUMN company.company_country IS 'Company country.';

-- Drop existing functions (required when signature or return type changes)
DROP FUNCTION IF EXISTS company_get_profile(INTEGER);
DROP FUNCTION IF EXISTS company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION company_get_profile(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    company_name TEXT,
    company_address TEXT,
    company_address2 TEXT,
    company_city TEXT,
    company_state TEXT,
    company_zip_code TEXT,
    company_country TEXT,
    company_phone TEXT,
    locale TEXT,
    logo_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.company_name, c.company_address, c.company_address2, c.company_city, c.company_state,
           c.company_zip_code, c.company_country, c.company_phone, c.locale, c.logo_url
    FROM company c
    WHERE c.id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION company_update_profile(
    p_id INTEGER,
    p_company_name TEXT DEFAULT NULL,
    p_company_address TEXT DEFAULT NULL,
    p_company_address2 TEXT DEFAULT NULL,
    p_company_city TEXT DEFAULT NULL,
    p_company_state TEXT DEFAULT NULL,
    p_company_zip_code TEXT DEFAULT NULL,
    p_company_country TEXT DEFAULT NULL,
    p_company_phone TEXT DEFAULT NULL,
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
        company_address = COALESCE(p_company_address, company_address),
        company_address2 = COALESCE(p_company_address2, company_address2),
        company_city = COALESCE(p_company_city, company_city),
        company_state = COALESCE(p_company_state, company_state),
        company_zip_code = COALESCE(p_company_zip_code, company_zip_code),
        company_country = COALESCE(p_company_country, company_country),
        company_phone = COALESCE(p_company_phone, company_phone),
        locale = COALESCE(p_locale, locale),
        logo_url = COALESCE(p_logo_url, logo_url),
        last_modified_date = NOW()
    WHERE id = p_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION company_get_profile(INTEGER) IS 'Returns company profile for display and edit.';
COMMENT ON FUNCTION company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates company profile fields.';
