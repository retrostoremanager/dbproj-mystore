-- 062_create_app_user_role.sql
--
-- Dedicated application login role that is SUBJECT TO Row-Level Security. The app must connect
-- as this role (not sqladmin) for the tenant_isolation policies from 061 to actually enforce:
-- the Azure admin role `sqladmin` has the BYPASSRLS attribute, so connecting as it skips RLS
-- entirely even with FORCE. `app_user` is created NOBYPASSRLS and is not a table owner, so RLS
-- applies normally.
--
-- The password is intentionally NOT set here (it is a secret). Until a password is set AND the
-- app's connection string is switched to app_user, this role cannot log in and nothing changes
-- (sqladmin keeps connecting, RLS stays bypassed -- the current safe state). Migrations continue
-- to run as sqladmin (the owner), which is correct.
--
-- Idempotent: safe to re-run.

-- A freshly created role defaults to NOBYPASSRLS / NOSUPERUSER / NOCREATEDB / NOCREATEROLE,
-- which is exactly what we want (only Azure's admin role sqladmin was given BYPASSRLS). We do
-- NOT ALTER those attributes: on Azure Flexible Server sqladmin is not a superuser and cannot
-- change the bypassrls/superuser attributes (ERROR 42501 "must be superuser"), and need not.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN;
    END IF;
END $$;

-- Connect privilege (CONNECT is granted to PUBLIC by default, but be explicit and db-agnostic).
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO app_user', current_database());
END $$;

-- CRUD on all current tables + execute functions + sequence usage (for SERIAL/identity inserts).
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- Same privileges for tables/sequences/functions created in the future by sqladmin (migrations).
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO app_user;
