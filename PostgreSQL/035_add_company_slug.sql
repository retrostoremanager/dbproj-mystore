-- EPIC: Path-based login - Add company slug for /c/{slug}/login URLs
-- Slug is unique, derived from company_name. Used for company-specific login pages.

-- Add slug column
ALTER TABLE company ADD COLUMN IF NOT EXISTS slug TEXT;

-- Generate slugs for existing companies from company_name
UPDATE company
SET slug = LOWER(REGEXP_REPLACE(COALESCE(company_name, 'company-' || id::TEXT), '[^a-zA-Z0-9]+', '-', 'g'))
WHERE slug IS NULL;

-- Remove leading/trailing hyphens and collapse multiple hyphens
UPDATE company
SET slug = REGEXP_REPLACE(TRIM(BOTH '-' FROM slug), '-+', '-', 'g')
WHERE slug IS NOT NULL;

-- Ensure no empty slugs
UPDATE company SET slug = 'company-' || id::TEXT WHERE slug IS NULL OR slug = '';

-- Handle slug uniqueness: append suffix for duplicates
WITH numbered AS (
  SELECT id, slug,
    ROW_NUMBER() OVER (PARTITION BY slug ORDER BY id) AS rn
  FROM company
)
UPDATE company c
SET slug = CASE
  WHEN n.rn > 1 THEN n.slug || '-' || n.rn
  ELSE n.slug
END
FROM numbered n
WHERE c.id = n.id;

-- Make slug NOT NULL and add unique constraint
ALTER TABLE company ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ix_company_slug ON company(slug);

COMMENT ON COLUMN company.slug IS 'URL-friendly identifier for path-based login (e.g. /c/acme/login). Unique across all companies.';

-- Update company_get_by_id to include slug (for post-create fetch)
DROP FUNCTION IF EXISTS company_get_by_id(INTEGER);
CREATE OR REPLACE FUNCTION company_get_by_id(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    email TEXT,
    password_hash TEXT,
    status TEXT,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    verification_token TEXT,
    verification_token_expires TIMESTAMPTZ,
    password_reset_token TEXT,
    password_reset_token_expires TIMESTAMPTZ,
    subscription_tier TEXT,
    created_date TIMESTAMPTZ,
    last_modified_date TIMESTAMPTZ,
    company_name TEXT,
    slug TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.password_hash, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires,
           c.password_reset_token, c.password_reset_token_expires,
           c.subscription_tier, c.created_date, c.last_modified_date,
           c.company_name, c.slug
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Add company_get_by_slug function
CREATE OR REPLACE FUNCTION company_get_by_slug(p_slug TEXT)
RETURNS TABLE (
    id INTEGER,
    email TEXT,
    password_hash TEXT,
    status TEXT,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    verification_token TEXT,
    verification_token_expires TIMESTAMPTZ,
    password_reset_token TEXT,
    password_reset_token_expires TIMESTAMPTZ,
    subscription_tier TEXT,
    created_date TIMESTAMPTZ,
    last_modified_date TIMESTAMPTZ,
    company_name TEXT,
    slug TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.password_hash, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires,
           c.password_reset_token, c.password_reset_token_expires,
           c.subscription_tier, c.created_date, c.last_modified_date,
           c.company_name, c.slug
    FROM company c
    WHERE LOWER(TRIM(c.slug)) = LOWER(TRIM(p_slug));
END;
$$;

-- Update company_create to accept slug
DROP FUNCTION IF EXISTS company_create(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT);

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
    p_company_name TEXT DEFAULT NULL,
    p_slug TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
    v_slug TEXT;
    v_base_slug TEXT;
    v_counter INT := 1;
BEGIN
    -- Generate base slug from company_name if not provided
    v_base_slug := COALESCE(NULLIF(TRIM(p_slug), ''), 
        LOWER(REGEXP_REPLACE(COALESCE(p_company_name, 'company'), '[^a-zA-Z0-9]+', '-', 'g')));
    v_base_slug := REGEXP_REPLACE(TRIM(BOTH '-' FROM v_base_slug), '-+', '-', 'g');
    IF v_base_slug = '' THEN v_base_slug := 'company'; END IF;

    v_slug := v_base_slug;
    -- Ensure slug uniqueness (append -2, -3, etc. if collision)
    WHILE EXISTS (SELECT 1 FROM company WHERE LOWER(slug) = LOWER(v_slug)) LOOP
        v_counter := v_counter + 1;
        v_slug := v_base_slug || '-' || v_counter;
    END LOOP;

    INSERT INTO company (
        email, status, trial_start_date, trial_end_date,
        verification_token, verification_token_expires, subscription_tier,
        created_date, last_modified_date, password_hash, company_name, slug
    )
    VALUES (
        p_email, p_status, p_trial_start_date, p_trial_end_date,
        p_verification_token, p_verification_token_expires, p_subscription_tier,
        p_created_date, p_last_modified_date, p_password_hash, p_company_name, v_slug
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;
