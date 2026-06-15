-- Issue #163: Tax settings — add tax columns to company and sale tables

-- Add tax configuration columns to company table
ALTER TABLE company ADD COLUMN IF NOT EXISTS tax_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE company ADD COLUMN IF NOT EXISTS tax_rate DECIMAL(5,4) NOT NULL DEFAULT 0;
ALTER TABLE company ADD COLUMN IF NOT EXISTS tax_label VARCHAR(50) NOT NULL DEFAULT 'Sales Tax';

-- Add subtotal and tax_amount columns to sale table (nullable to preserve existing rows)
ALTER TABLE sale ADD COLUMN IF NOT EXISTS subtotal_amount DECIMAL(10,2);
ALTER TABLE sale ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2);

COMMENT ON COLUMN company.tax_enabled IS 'Whether tax collection is enabled for this company.';
COMMENT ON COLUMN company.tax_rate IS 'Tax rate as decimal (e.g. 0.0875 for 8.75%). Range: 0.0000 to 0.9999.';
COMMENT ON COLUMN company.tax_label IS 'Label for the tax (e.g. Sales Tax, GST, VAT).';
COMMENT ON COLUMN sale.subtotal_amount IS 'Pre-tax subtotal for the sale. Nullable to preserve existing rows.';
COMMENT ON COLUMN sale.tax_amount IS 'Tax amount applied to the sale. Nullable to preserve existing rows.';

-- Drop existing company_get_tax_settings if present (idempotent)
DROP FUNCTION IF EXISTS company_get_tax_settings(INTEGER);
DROP FUNCTION IF EXISTS company_update_tax_settings(INTEGER, BOOLEAN, DECIMAL, VARCHAR);

-- Get tax settings for a company
CREATE OR REPLACE FUNCTION company_get_tax_settings(p_id INTEGER)
RETURNS TABLE (
    tax_enabled BOOLEAN,
    tax_rate DECIMAL(5,4),
    tax_label VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.tax_enabled, c.tax_rate, c.tax_label
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Update tax settings for a company
CREATE OR REPLACE FUNCTION company_update_tax_settings(
    p_id INTEGER,
    p_tax_enabled BOOLEAN,
    p_tax_rate DECIMAL(5,4),
    p_tax_label VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET tax_enabled = p_tax_enabled,
        tax_rate = p_tax_rate,
        tax_label = p_tax_label,
        last_modified_date = NOW()
    WHERE id = p_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;

COMMENT ON FUNCTION company_get_tax_settings(INTEGER) IS 'Returns tax configuration for a company.';
COMMENT ON FUNCTION company_update_tax_settings(INTEGER, BOOLEAN, DECIMAL, VARCHAR) IS 'Updates tax configuration for a company.';
