-- Add password_hash column for custom authentication (MVP)
-- Existing rows will have NULL; new signups will store bcrypt hash
ALTER TABLE company ADD COLUMN IF NOT EXISTS password_hash TEXT;

COMMENT ON COLUMN company.password_hash IS 'Bcrypt hash of user password for custom sign-in (MVP)';
