-- Simplify company profile: Company (name, address, phone) + Locations (each with timezone)
-- Remove store type; company address/phone separate from location address/phone; timezone per location
-- Idempotent: safe to run on already-migrated DBs (e.g. when store_* already renamed to company_*)

-- 1. Migrate store_* to company_* and add timezone to location
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_address') THEN
    ALTER TABLE company RENAME COLUMN store_address TO company_address;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_city') THEN
    ALTER TABLE company RENAME COLUMN store_city TO company_city;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_state') THEN
    ALTER TABLE company RENAME COLUMN store_state TO company_state;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_zip_code') THEN
    ALTER TABLE company RENAME COLUMN store_zip_code TO company_zip_code;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_phone') THEN
    ALTER TABLE company RENAME COLUMN store_phone TO company_phone;
  END IF;
END $$;

-- Migrate store_name to company_name where company_name is null (only if store_name exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'company' AND column_name = 'store_name') THEN
    UPDATE company SET company_name = store_name WHERE company_name IS NULL AND store_name IS NOT NULL;
  END IF;
END $$;

-- Drop removed columns
ALTER TABLE company DROP COLUMN IF EXISTS store_name;
ALTER TABLE company DROP COLUMN IF EXISTS store_type;
ALTER TABLE company DROP COLUMN IF EXISTS timezone;

COMMENT ON COLUMN company.company_address IS 'Company mailing address or headquarters (can differ from location addresses).';
COMMENT ON COLUMN company.company_phone IS 'Company phone (can differ from location phones).';

-- Add timezone to location (per-location, e.g. for multi-timezone companies)
ALTER TABLE location ADD COLUMN IF NOT EXISTS timezone TEXT;
COMMENT ON COLUMN location.timezone IS 'IANA timezone for this location (e.g. America/New_York).';

-- 2. Update company profile functions
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

-- 3. Update location functions to include timezone
DROP FUNCTION IF EXISTS location_get_by_company_id(INTEGER);
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

DROP FUNCTION IF EXISTS location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);
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

DROP FUNCTION IF EXISTS location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN);
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

COMMENT ON FUNCTION company_get_profile(INTEGER) IS 'Returns company profile: name, address, phone.';
COMMENT ON FUNCTION company_update_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates company profile.';
COMMENT ON FUNCTION location_create(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Creates a location with optional timezone.';
COMMENT ON FUNCTION location_update(INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Updates a location including timezone.';
