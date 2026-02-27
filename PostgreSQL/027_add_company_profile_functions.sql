-- EPIC-0-007-001: Company profile get/update functions
-- Separate from company_update to keep auth logic clean

-- Get company profile (store info only; for profile display/edit)
CREATE OR REPLACE FUNCTION company_get_profile(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
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
    SELECT c.id, c.store_name, c.store_type, c.store_address, c.store_city, c.store_state,
           c.store_zip_code, c.store_phone, c.timezone, c.locale, c.logo_url
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Update company profile
CREATE OR REPLACE FUNCTION company_update_profile(
    p_id INTEGER,
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
    SET store_name = COALESCE(p_store_name, store_name),
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

COMMENT ON FUNCTION company_get_profile(INTEGER) IS 'Returns company profile/store info for display and edit.';
COMMENT ON FUNCTION company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates company profile fields.';
