-- Add invitation_expired status for users whose invite link has expired.
-- Users with status pending_invitation and password_invite_token_expires < NOW() are updated to invitation_expired.
-- Resend invite sets them back to pending_invitation with a new token.

ALTER TABLE "user" DROP CONSTRAINT IF EXISTS ck_user_status;
ALTER TABLE "user" ADD CONSTRAINT ck_user_status CHECK (status IN ('pending_invitation', 'invitation_expired', 'active', 'removed'));

COMMENT ON COLUMN "user".status IS 'pending_invitation, invitation_expired, active, or removed.';
