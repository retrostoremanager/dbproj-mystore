-- EPIC-0-007-001: Company profile get/update functions
-- Separate from company_update to keep auth logic clean

-- Get company profile (company info for profile display/edit)
CREATE OR REPLACE FUNCTION company_get_profile(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    company_name TEXT,
    company_address TEXT,
    company_city TEXT,
    company_state TEXT,
    company_zip_code TEXT,
    company_phone TEXT,
    locale TEXT,
    logo_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.company_name, c.company_address, c.company_city, c.company_state,
           c.company_zip_code, c.company_phone, c.locale, c.logo_url
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Update company profile
CREATE OR REPLACE FUNCTION company_update_profile(
    p_id INTEGER,
    p_company_name TEXT DEFAULT NULL,
    p_company_address TEXT DEFAULT NULL,
    p_company_city TEXT DEFAULT NULL,
    p_company_state TEXT DEFAULT NULL,
    p_company_zip_code TEXT DEFAULT NULL,
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
        company_city = COALESCE(p_company_city, company_city),
        company_state = COALESCE(p_company_state, company_state),
        company_zip_code = COALESCE(p_company_zip_code, company_zip_code),
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
COMMENT ON FUNCTION company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates company profile fields.';
