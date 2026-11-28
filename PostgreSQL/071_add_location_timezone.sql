-- Add location.timezone -- fn-mystore issue found 2026-11-28.
--
-- Commit 184571f ("Simplify profile: Company + Locations, timezone per location") added
-- a Timezone field to the Location model and wired LocationRepository.CreateAsync /
-- UpdateAsync to pass a p_timezone argument to location_create / location_update, and the
-- web-mystore Add Location form already has a Timezone picker. But the corresponding
-- schema change never shipped: 026_create_location_functions.sql's location_create/
-- location_update still take only 8 params (no timezone), so every location_create call
-- from the app has always failed with "function location_create(...) does not exist" --
-- i.e. every attempt to add a store location has always 500'd.
--
-- This finishes that migration: adds the column and republishes the 3 functions to
-- accept/return it, so the app code (already shipped, unchanged here) starts working.

ALTER TABLE location ADD COLUMN IF NOT EXISTS timezone TEXT;

DROP FUNCTION IF EXISTS location_get_by_company_id(INTEGER);
DROP FUNCTION IF EXISTS location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);

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
    timezone TEXT,
    is_primary BOOLEAN,
    created_date TIMESTAMPTZ,
    last_modified_date TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.company_id, l.name, l.address, l.city, l.state, l.zip_code, l.phone,
           l.timezone, l.is_primary, l.created_date, l.last_modified_date
    FROM location l
    WHERE l.company_id = p_company_id
    ORDER BY l.is_primary DESC, l.name;
END;
$$;

CREATE OR REPLACE FUNCTION location_create(
    p_company_id INTEGER,
    p_name TEXT,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_zip_code TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_timezone TEXT DEFAULT NULL,
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

    INSERT INTO location (company_id, name, address, city, state, zip_code, phone, timezone, is_primary, created_date)
    VALUES (p_company_id, p_name, p_address, p_city, p_state, p_zip_code, p_phone, p_timezone, p_is_primary, NOW())
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION location_update(
    p_id INTEGER,
    p_company_id INTEGER,
    p_name TEXT,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_zip_code TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_timezone TEXT DEFAULT NULL,
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
        zip_code = p_zip_code, phone = p_phone, timezone = p_timezone, is_primary = p_is_primary,
        last_modified_date = NOW()
    WHERE id = p_id AND company_id = p_company_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION location_get_by_company_id(INTEGER) IS 'Returns all locations for a company.';
COMMENT ON FUNCTION location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Creates a new location.';
COMMENT ON FUNCTION location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Updates a location.';
