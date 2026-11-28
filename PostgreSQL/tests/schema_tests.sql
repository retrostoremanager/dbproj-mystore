-- Schema + constraint tests for mystore-db. Run against a freshly-migrated database
-- (after PostgreSQL/000_deploy_all.sql) -- never against dev/prod, since several checks
-- insert/delete real rows.
--
-- Plain SQL assertions (no pgTAP or other extension) so there's zero extra tooling beyond
-- psql, which migrations already require. Each check either passes silently or RAISEs an
-- exception, which makes psql exit non-zero -- that's what fails the CI job.
--
-- NOT exhaustive: this schema has ~20 tables across 35+ migrations. This covers the core
-- multi-tenant/auth/billing tables (company, user/role/permission, subscription/
-- subscription_addon) as a starting point -- add to this file as new migrations land,
-- the same way application code gets new tests. Checked against the actual final schema
-- (not just the original CREATE TABLE migrations in isolation) since several of these
-- tables are altered by later migrations -- e.g. "user" lost employee_id and gained
-- password_hash/phone, and both ck_user_type and ck_user_status gained extra allowed
-- values after the migrations that originally created them.

\set ON_ERROR_STOP on

CREATE OR REPLACE FUNCTION pg_temp.assert(condition boolean, message text) RETURNS void AS $$
BEGIN
    IF NOT condition THEN
        RAISE EXCEPTION 'ASSERTION FAILED: %', message;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Test companies only need to satisfy company's own NOT NULL/UNIQUE columns (email, slug);
-- callers provide a unique slug so they don't collide with each other or with seed data.
CREATE OR REPLACE FUNCTION pg_temp.create_test_company(p_slug text, p_email text) RETURNS int AS $$
DECLARE
    v_id int;
BEGIN
    INSERT INTO company (email, slug, status, trial_start_date, trial_end_date, subscription_tier, created_date)
    VALUES (p_email, p_slug, 'Active', NOW(), NOW(), 'Trial', NOW())
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ===== Tables exist =====

DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['company', 'user', 'role', 'permission', 'role_permission',
                              'user_role', 'subscription', 'subscription_addon']
    LOOP
        PERFORM pg_temp.assert(
            EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = t),
            format('%s table should exist', t));
    END LOOP;
END $$;

-- ===== company =====

-- email is unique.
DO $$
BEGIN
    PERFORM pg_temp.create_test_company('dup-email-test-1', 'dup-test@example.com');

    BEGIN
        PERFORM pg_temp.create_test_company('dup-email-test-2', 'dup-test@example.com');
        RAISE EXCEPTION 'ASSERTION FAILED: a duplicate company.email should have been rejected';
    EXCEPTION
        WHEN unique_violation THEN NULL; -- expected
    END;
END $$;

-- slug is unique too (used for URL routing).
DO $$
BEGIN
    PERFORM pg_temp.create_test_company('dup-slug-test', 'slug-test-1@example.com');

    BEGIN
        PERFORM pg_temp.create_test_company('dup-slug-test', 'slug-test-2@example.com');
        RAISE EXCEPTION 'ASSERTION FAILED: a duplicate company.slug should have been rejected';
    EXCEPTION
        WHEN unique_violation THEN NULL; -- expected
    END;
END $$;

-- ===== user =====

DO $$
DECLARE
    v_company_id int;
BEGIN
    v_company_id := pg_temp.create_test_company('user-test', 'user-test@example.com');

    -- ck_user_type only allows owner/employee/customer.
    BEGIN
        INSERT INTO "user" (company_id, email, first_name, last_name, user_type)
        VALUES (v_company_id, 'a@example.com', 'A', 'B', 'superadmin');
        RAISE EXCEPTION 'ASSERTION FAILED: an invalid user_type should have been rejected';
    EXCEPTION
        WHEN check_violation THEN NULL; -- expected
    END;

    -- ck_user_status only allows the 4 known values.
    BEGIN
        INSERT INTO "user" (company_id, email, first_name, last_name, user_type, status)
        VALUES (v_company_id, 'a@example.com', 'A', 'B', 'employee', 'banned');
        RAISE EXCEPTION 'ASSERTION FAILED: an invalid user status should have been rejected';
    EXCEPTION
        WHEN check_violation THEN NULL; -- expected
    END;

    -- uq_user_company_email: email unique per company, but the SAME email can belong to
    -- users at DIFFERENT companies (no cross-tenant uniqueness).
    INSERT INTO "user" (company_id, email, first_name, last_name, user_type)
    VALUES (v_company_id, 'dup@example.com', 'A', 'B', 'employee');

    BEGIN
        INSERT INTO "user" (company_id, email, first_name, last_name, user_type)
        VALUES (v_company_id, 'dup@example.com', 'C', 'D', 'employee');
        RAISE EXCEPTION 'ASSERTION FAILED: a duplicate email within the same company should have been rejected';
    EXCEPTION
        WHEN unique_violation THEN NULL; -- expected
    END;

    -- Deleting the company should cascade-delete its users.
    DELETE FROM company WHERE id = v_company_id;
    PERFORM pg_temp.assert(
        NOT EXISTS (SELECT 1 FROM "user" WHERE company_id = v_company_id),
        'deleting a company should cascade-delete its users');
END $$;

-- ===== role / permission seed data =====
-- Seeded once by migration 031 (idempotent) -- these tests just confirm it's actually
-- there and shaped the way the application assumes, not re-seed it themselves.

DO $$
BEGIN
    PERFORM pg_temp.assert(
        (SELECT COUNT(*) FROM role WHERE company_id IS NULL
            AND name IN ('Owner', 'Manager', 'Employee', 'Cashier')) = 4,
        'all 4 system roles (Owner/Manager/Employee/Cashier) should exist with company_id NULL');

    PERFORM pg_temp.assert(
        (SELECT COUNT(*) FROM permission WHERE name = 'inventory.view') = 1,
        'the inventory.view permission should exist');

    -- Owner has every permission that currently exists.
    PERFORM pg_temp.assert(
        (SELECT COUNT(*) FROM role_permission rp
            JOIN role r ON r.id = rp.role_id
            WHERE r.company_id IS NULL AND r.name = 'Owner')
        = (SELECT COUNT(*) FROM permission),
        'the system Owner role should have every permission');

    -- Cashier is scoped down -- it should NOT have inventory.create (spot-check the
    -- least-privilege design, not just that the role exists).
    PERFORM pg_temp.assert(
        NOT EXISTS (
            SELECT 1 FROM role_permission rp
            JOIN role r ON r.id = rp.role_id
            JOIN permission p ON p.id = rp.permission_id
            WHERE r.company_id IS NULL AND r.name = 'Cashier' AND p.name = 'inventory.create'
        ),
        'the system Cashier role should not have inventory.create');
END $$;

-- ===== subscription / subscription_addon =====

DO $$
DECLARE
    v_company_id int;
    v_subscription_id int;
BEGIN
    v_company_id := pg_temp.create_test_company('sub-test', 'sub-test@example.com');

    INSERT INTO subscription (company_id, stripe_subscription_id, stripe_customer_id, status)
    VALUES (v_company_id, 'sub_test_12345', 'cus_test_12345', 'active')
    RETURNING id INTO v_subscription_id;

    -- stripe_subscription_id is unique across all companies.
    BEGIN
        INSERT INTO subscription (company_id, stripe_subscription_id, stripe_customer_id, status)
        VALUES (v_company_id, 'sub_test_12345', 'cus_test_99999', 'active');
        RAISE EXCEPTION 'ASSERTION FAILED: a duplicate stripe_subscription_id should have been rejected';
    EXCEPTION
        WHEN unique_violation THEN NULL; -- expected
    END;

    INSERT INTO subscription_addon (subscription_id, addon_type, stripe_subscription_item_id, stripe_price_id, status)
    VALUES (v_subscription_id, 'lot_scanner', 'si_test_12345', 'price_test_12345', 'active');

    -- A company can't subscribe to the same add-on twice on one subscription.
    BEGIN
        INSERT INTO subscription_addon (subscription_id, addon_type, stripe_subscription_item_id, stripe_price_id, status)
        VALUES (v_subscription_id, 'lot_scanner', 'si_test_99999', 'price_test_99999', 'active');
        RAISE EXCEPTION 'ASSERTION FAILED: a duplicate (subscription_id, addon_type) should have been rejected';
    EXCEPTION
        WHEN unique_violation THEN NULL; -- expected
    END;

    -- Deleting the subscription should cascade-delete its add-ons.
    DELETE FROM subscription WHERE id = v_subscription_id;
    PERFORM pg_temp.assert(
        NOT EXISTS (SELECT 1 FROM subscription_addon WHERE subscription_id = v_subscription_id),
        'deleting a subscription should cascade-delete its subscription_addon rows');

    DELETE FROM company WHERE id = v_company_id;
END $$;

-- ===== game_inventory (070) =====
-- name/category must be nullable: the app (InventoryRepository, TradeInRepository) never
-- populates them -- it derives Name/Category from a game_encyclopedia join instead.

DO $$
DECLARE
    v_company_id int;
    v_location_id int;
BEGIN
    v_company_id := pg_temp.create_test_company('game-inv-test', 'game-inv-test@example.com');

    INSERT INTO location (company_id, name, is_primary, created_date)
    VALUES (v_company_id, 'Test Location', true, NOW())
    RETURNING id INTO v_location_id;

    -- Should succeed with name/category omitted entirely.
    INSERT INTO game_inventory (company_id, location_id, quantity, sell_price, buy_price, condition, added_date)
    VALUES (v_company_id, v_location_id, 1, 9.99, 4.00, 'Good', NOW());

    -- game_inventory has no ON DELETE CASCADE from company (unlike location), so clean it
    -- up explicitly or the company delete below would fail on the FK.
    DELETE FROM game_inventory WHERE company_id = v_company_id;
    DELETE FROM company WHERE id = v_company_id;
END $$;

-- ===== location (071) =====
-- timezone column + location_create/location_update must accept it (app has passed
-- p_timezone since commit 184571f; the function signature must match).

DO $$
DECLARE
    v_company_id int;
    v_location_id int;
    v_timezone text;
BEGIN
    v_company_id := pg_temp.create_test_company('loc-tz-test', 'loc-tz-test@example.com');

    v_location_id := location_create(v_company_id, 'Main Store', NULL, NULL, NULL, NULL, NULL, 'America/New_York', true);

    SELECT timezone INTO v_timezone FROM location WHERE id = v_location_id;
    PERFORM pg_temp.assert(v_timezone = 'America/New_York', 'location_create should persist timezone');

    PERFORM location_update(v_location_id, v_company_id, 'Main Store', NULL, NULL, NULL, NULL, NULL, 'America/Chicago', true);
    SELECT timezone INTO v_timezone FROM location WHERE id = v_location_id;
    PERFORM pg_temp.assert(v_timezone = 'America/Chicago', 'location_update should update timezone');

    PERFORM pg_temp.assert(
        (SELECT timezone FROM location_get_by_company_id(v_company_id) WHERE id = v_location_id) = 'America/Chicago',
        'location_get_by_company_id should return timezone');

    DELETE FROM company WHERE id = v_company_id;
END $$;

-- ===== sale / sale_item / sale_promotion (072) =====
-- Mirrors exactly the columns SalesRepository.CreateAsync writes (minus created_date,
-- which was never read anywhere and was removed from the INSERT rather than migrated).

DO $$
DECLARE
    v_company_id int;
    v_location_id int;
    v_customer_id int;
    v_user_id int;
    v_promotion_id int;
    v_inventory_id int;
    v_sale_id int;
    v_sale_item_id int;
BEGIN
    v_company_id := pg_temp.create_test_company('sale-promo-test', 'sale-promo-test@example.com');

    INSERT INTO location (company_id, name, is_primary, created_date)
    VALUES (v_company_id, 'Test Location', true, NOW())
    RETURNING id INTO v_location_id;

    INSERT INTO customer (company_id, first_name, last_name, email, created_date)
    VALUES (v_company_id, 'Cust', 'Omer', 'sale-promo-cust@example.com', NOW())
    RETURNING id INTO v_customer_id;

    INSERT INTO "user" (company_id, email, first_name, last_name)
    VALUES (v_company_id, 'sale-promo-user@example.com', 'Test', 'User')
    RETURNING id INTO v_user_id;

    INSERT INTO promotion (company_id, name, type, discount_percent, scope, start_date, is_active, created_by)
    VALUES (v_company_id, '10% Off', 'percentage', 10, 'store_wide', NOW() - INTERVAL '1 day', true, v_user_id)
    RETURNING id INTO v_promotion_id;

    INSERT INTO game_inventory (company_id, location_id, quantity, sell_price, buy_price, condition, added_date)
    VALUES (v_company_id, v_location_id, 5, 19.99, 10.00, 'Good', NOW())
    RETURNING id INTO v_inventory_id;

    -- Exact column set SalesRepository.CreateAsync's insertSale writes (no created_date).
    INSERT INTO sale (company_id, customer_id, user_id, subtotal, tax, total_amount,
                       subtotal_amount, tax_amount, discount_total, payment_method, sale_date, notes)
    VALUES (v_company_id, v_customer_id, v_user_id, 19.99, 1.65, 19.80,
            19.99, 1.65, 2.00, 'Cash', NOW(), 'schema test sale')
    RETURNING id INTO v_sale_id;

    -- Exact column set insertItem writes (no subtotal/created_date -- neither read anywhere).
    INSERT INTO sale_item (sale_id, inventory_item_id, quantity, unit_price, total_price,
                            discount_amount, promotion_id, promotion_name)
    VALUES (v_sale_id, v_inventory_id, 1, 19.99, 19.99, 2.00, v_promotion_id, '10% Off')
    RETURNING id INTO v_sale_item_id;

    INSERT INTO sale_promotion (sale_id, promotion_id, promotion_name, discount_amount)
    VALUES (v_sale_id, v_promotion_id, '10% Off', 2.00);

    PERFORM pg_temp.assert(
        (SELECT discount_total FROM sale WHERE id = v_sale_id) = 2.00,
        'sale.discount_total should round-trip');
    PERFORM pg_temp.assert(
        (SELECT discount_amount FROM sale_item WHERE id = v_sale_item_id) = 2.00,
        'sale_item.discount_amount should round-trip');
    PERFORM pg_temp.assert(
        (SELECT COUNT(*) FROM sale_promotion WHERE sale_id = v_sale_id) = 1,
        'sale_promotion row should be inserted');

    -- Deleting the promotion should null out the FK, not delete sale history.
    DELETE FROM promotion WHERE id = v_promotion_id;
    PERFORM pg_temp.assert(
        (SELECT promotion_id FROM sale_item WHERE id = v_sale_item_id) IS NULL,
        'deleting a promotion should null sale_item.promotion_id, not delete the sale_item');
    PERFORM pg_temp.assert(
        (SELECT COUNT(*) FROM sale_promotion WHERE sale_id = v_sale_id) = 1,
        'deleting a promotion should not delete the sale_promotion row');

    -- Deleting the sale should cascade-delete its items and promotion breakdown.
    DELETE FROM sale WHERE id = v_sale_id;
    PERFORM pg_temp.assert(
        NOT EXISTS (SELECT 1 FROM sale_item WHERE sale_id = v_sale_id),
        'deleting a sale should cascade-delete its sale_item rows');
    PERFORM pg_temp.assert(
        NOT EXISTS (SELECT 1 FROM sale_promotion WHERE sale_id = v_sale_id),
        'deleting a sale should cascade-delete its sale_promotion rows');

    DELETE FROM game_inventory WHERE id = v_inventory_id;
    DELETE FROM customer WHERE id = v_customer_id;
    DELETE FROM company WHERE id = v_company_id;
END $$;

SELECT 'All mystore schema tests passed.' AS result;
