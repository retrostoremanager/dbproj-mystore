-- EPIC-0-007-001: Company Profile Database Schema
-- Add store profile columns to company table

-- Store name (required per business rules; unique per company - company is the account)
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_name TEXT;
-- Store type: retro_game_store, card_store, both
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_type TEXT;
-- Address and contact
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_address TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_city TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_state TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_zip_code TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS store_phone TEXT;
-- Timezone (IANA, e.g. America/New_York) and locale (e.g. en-US)
ALTER TABLE company ADD COLUMN IF NOT EXISTS timezone TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS locale TEXT;
-- Logo URL (path in blob storage; 5MB limit enforced at upload)
ALTER TABLE company ADD COLUMN IF NOT EXISTS logo_url TEXT;

COMMENT ON COLUMN company.store_name IS 'Display name of the store. Required for profile.';
COMMENT ON COLUMN company.store_type IS 'Store type: retro_game_store, card_store, or both. Affects available features.';
COMMENT ON COLUMN company.timezone IS 'IANA timezone (e.g. America/New_York) for date/time display.';
COMMENT ON COLUMN company.locale IS 'Locale for formatting (e.g. en-US).';
COMMENT ON COLUMN company.logo_url IS 'URL to logo in blob storage. Max 5MB, PNG/JPG/SVG.';
