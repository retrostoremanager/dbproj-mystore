-- Reserve slugs that conflict with system routes (/{slug} URLs)
-- When company name would produce a reserved slug, append '-store' to avoid conflicts.

-- Fix existing companies with reserved slugs
UPDATE company
SET slug = slug || '-store'
WHERE LOWER(slug) IN ('dashboard', 'signup', 'verify', 'forgot-password', 'reset-password', 'set-password', 'login', 'c', 'api', 'admin');

-- Resolve duplicate slugs (e.g. two companies both had "dashboard")
WITH numbered AS (
  SELECT id, slug,
    ROW_NUMBER() OVER (PARTITION BY slug ORDER BY id) AS rn
  FROM company
)
UPDATE company c
SET slug = CASE WHEN n.rn > 1 THEN n.slug || '-' || n.rn ELSE n.slug END
FROM numbered n
WHERE c.id = n.id;

-- Update company_create to reject reserved slugs and append '-store' when needed
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
    v_reserved_slugs TEXT[] := ARRAY[
        'dashboard', 'signup', 'verify', 'forgot-password', 'reset-password',
        'set-password', 'login', 'c', 'api', 'admin'
    ];
BEGIN
    -- Generate base slug from company_name if not provided
    v_base_slug := COALESCE(NULLIF(TRIM(p_slug), ''),
        LOWER(REGEXP_REPLACE(COALESCE(p_company_name, 'company'), '[^a-zA-Z0-9]+', '-', 'g')));
    v_base_slug := REGEXP_REPLACE(TRIM(BOTH '-' FROM v_base_slug), '-+', '-', 'g');
    IF v_base_slug = '' THEN v_base_slug := 'company'; END IF;

    -- If base slug conflicts with system routes, append '-store'
    IF LOWER(v_base_slug) = ANY(v_reserved_slugs) THEN
        v_base_slug := v_base_slug || '-store';
    END IF;

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
