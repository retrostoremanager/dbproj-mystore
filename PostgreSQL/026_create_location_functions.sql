-- EPIC-0-007-001: Location table CRUD functions

-- Get locations by company ID
CREATE OR REPLACE FUNCTION location_get_by_company_id(p_company_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    company_id INTEGER,
    name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    phone TEXT,
    is_primary BOOLEAN,
    created_date TIMESTAMPTZ,
    last_modified_date TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.company_id, l.name, l.address, l.city, l.state, l.zip_code, l.phone,
           l.is_primary, l.created_date, l.last_modified_date
    FROM location l
    WHERE l.company_id = p_company_id
    ORDER BY l.is_primary DESC, l.name;
END;
$$;

-- Create location
CREATE OR REPLACE FUNCTION location_create(
    p_company_id INTEGER,
    p_name TEXT,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_zip_code TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_is_primary THEN
        UPDATE location SET is_primary = false WHERE company_id = p_company_id;
    END IF;
    
    INSERT INTO location (company_id, name, address, city, state, zip_code, phone, is_primary, created_date)
    VALUES (p_company_id, p_name, p_address, p_city, p_state, p_zip_code, p_phone, p_is_primary, NOW())
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

-- Update location
CREATE OR REPLACE FUNCTION location_update(
    p_id INTEGER,
    p_company_id INTEGER,
    p_name TEXT,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_zip_code TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    IF p_is_primary THEN
        UPDATE location SET is_primary = false WHERE company_id = p_company_id AND id != p_id;
    END IF;
    
    UPDATE location
    SET name = p_name, address = p_address, city = p_city, state = p_state,
        zip_code = p_zip_code, phone = p_phone, is_primary = p_is_primary,
        last_modified_date = NOW()
    WHERE id = p_id AND company_id = p_company_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

-- Delete location
CREATE OR REPLACE FUNCTION location_delete(p_id INTEGER, p_company_id INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    DELETE FROM location WHERE id = p_id AND company_id = p_company_id;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION location_get_by_company_id(INTEGER) IS 'Returns all locations for a company.';
COMMENT ON FUNCTION location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Creates a new location.';
COMMENT ON FUNCTION location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Updates a location.';
COMMENT ON FUNCTION location_delete(INTEGER, INTEGER) IS 'Deletes a location.';
