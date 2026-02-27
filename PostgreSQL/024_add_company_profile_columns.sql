-- EPIC-0-007-001: Company Profile Database Schema
-- Add company profile columns (company_* naming)

-- Address and contact
ALTER TABLE company ADD COLUMN IF NOT EXISTS company_address TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS company_city TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS company_state TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS company_zip_code TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS company_phone TEXT;
-- Locale (e.g. en-US) and logo
ALTER TABLE company ADD COLUMN IF NOT EXISTS locale TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS logo_url TEXT;

COMMENT ON COLUMN company.company_address IS 'Company mailing address or headquarters (can differ from location addresses).';
COMMENT ON COLUMN company.company_phone IS 'Company phone (can differ from location phones).';
COMMENT ON COLUMN company.locale IS 'Locale for formatting (e.g. en-US).';
COMMENT ON COLUMN company.logo_url IS 'URL to logo in blob storage. Max 5MB, PNG/JPG/SVG.';
