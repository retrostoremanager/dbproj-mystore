-- Add password and invite token columns to user table for employee login.
-- Employees receive an invite email with a link to set their password.
-- After setting password, they can log in via company login page.

ALTER TABLE "user" ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS password_invite_token TEXT;
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS password_invite_token_expires TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS ix_user_password_invite_token ON "user"(password_invite_token) WHERE password_invite_token IS NOT NULL;

COMMENT ON COLUMN "user".password_hash IS 'BCrypt hash for employee login. NULL until user sets password from invite.';
COMMENT ON COLUMN "user".password_invite_token IS 'Token for invite/set-password flow. Cleared when password is set.';
COMMENT ON COLUMN "user".password_invite_token_expires IS 'Expiration for invite token. Typically 7 days.';
