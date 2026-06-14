-- 045_enable_row_level_security.sql
--
-- Database-level backstop for multi-tenant isolation. The application sets the
-- `app.current_company_id` session setting on every connection that touches these tables
-- (see fn-mystore: MyStore.Repositories/TenantConnection.cs). The policies below filter
-- every statement to that tenant, so a query that forgets a `company_id` predicate still
-- cannot read or write another company's rows.
--
-- ======================================================================================
-- ROLLOUT ORDER MATTERS — DO NOT DEPLOY THIS BEFORE THE APP IS SETTING app.current_company_id
-- ======================================================================================
-- The matching app change (fn-mystore branch `feat/rls-tenant-connection`) must be deployed
-- and verified in dev FIRST. If RLS is enabled while the app is NOT setting the GUC,
-- current_setting('app.current_company_id', true) returns NULL, every policy predicate is
-- false, and every query returns zero rows — an app-wide outage. Once the app is confirmed
-- setting the tenant on its DB connections, merge this to `development` to deploy.
--
-- Notes:
--  * FORCE ROW LEVEL SECURITY is required: the app connects as the table owner (sqladmin),
--    and owners bypass plain RLS. FORCE applies the policy to the owner too.
--  * missing_ok=true on current_setting means an unset GUC yields NULL (not an error);
--    NULL::int makes the predicate false -> fail-closed (zero rows), never a cross-tenant leak.
--  * Scope = parent tables that carry a company_id and whose every app access path sets the GUC.
--    Deliberately EXCLUDED for now (tracked as follow-up):
--      - child tables with no company_id: sale_item, trade_in_item, consignment_payout
--        (reachable only via their RLS-protected parent's FK from tenant-scoped code paths)
--      - location (accessed via SECURITY-context stored functions)
--      - auth/billing/catalog tables: company, "user", role, permission, payment_method,
--        subscription, game_encyclopedia (served by anonymous/login/webhook/timer paths that
--        have no tenant context)
--  * Operational caveat: with FORCE enabled, any admin/seed/backfill run as sqladmin that
--    INSERTs/UPDATEs these tables must also set app.current_company_id first (e.g.
--    `SELECT set_config('app.current_company_id', '<id>', false);`) or it will be filtered.
--  * Idempotent: ENABLE/FORCE are no-ops if already set; the policy is dropped and recreated.

DO $$
DECLARE
    t text;
    tenant_tables text[] := ARRAY[
        'customer',
        'game_inventory',
        'sale',
        'loyalty_transaction',
        'loyalty_settings',
        'promotion',
        'consignment_item',
        'trade_in'
    ];
BEGIN
    FOREACH t IN ARRAY tenant_tables LOOP
        IF to_regclass(t) IS NULL THEN
            RAISE NOTICE 'RLS: table % does not exist, skipping', t;
            CONTINUE;
        END IF;

        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', t);
        EXECUTE format(
            'CREATE POLICY tenant_isolation ON %I '
            'USING (company_id = current_setting(''app.current_company_id'', true)::int) '
            'WITH CHECK (company_id = current_setting(''app.current_company_id'', true)::int)',
            t);

        RAISE NOTICE 'RLS: enabled + forced tenant_isolation on %', t;
    END LOOP;
END $$;
