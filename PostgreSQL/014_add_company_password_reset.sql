-- Add password reset token columns for self-service password reset (EPIC-0-003)
-- Reset links expire after 1 hour and are single-use
ALTER TABLE company ADD COLUMN IF NOT EXISTS password_reset_token TEXT;
ALTER TABLE company ADD COLUMN IF NOT EXISTS password_reset_token_expires TIMESTAMPTZ;

-- Create partial index on password_reset_token (only non-null values)
CREATE INDEX IF NOT EXISTS ix_company_password_reset_token
    ON company(password_reset_token)
    WHERE password_reset_token IS NOT NULL;

COMMENT ON COLUMN company.password_reset_token IS 'Secure token for password reset link (single-use, 1 hour expiry)';
COMMENT ON COLUMN company.password_reset_token_expires IS 'Expiration timestamp for password reset token';
