-- Enforce one role per user: each user can have at most one role.
-- First, remove duplicate roles (keep one per user - lowest role_id).
-- Then add unique constraint on user_id.

-- 1. Remove duplicate user_role rows, keeping one per user (lowest role_id)
DELETE FROM user_role ur1
USING user_role ur2
WHERE ur1.user_id = ur2.user_id
  AND ur1.role_id > ur2.role_id;

-- 2. Add unique constraint so each user can only have one role
CREATE UNIQUE INDEX IF NOT EXISTS ix_user_role_user_id_unique ON user_role (user_id);

COMMENT ON INDEX ix_user_role_user_id_unique IS 'Enforces one role per user.';
