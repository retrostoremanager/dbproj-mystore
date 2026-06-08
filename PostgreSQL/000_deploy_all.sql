-- PostgreSQL Database Setup Script for MyStore
-- Execute this script to create all tables and functions

-- Run migrations in order
-- 1. Create all tables
\i 001_create_company_table.sql
\i 002_create_customer_table.sql
\i 003_create_employee_table.sql
\i 004_create_game_table.sql
\i 005_create_inventory_item_table.sql
\i 006_create_sale_table.sql
\i 007_create_sale_item_table.sql
\i 015_create_payment_method_table.sql
\i 016_add_company_stripe_customer_id.sql
\i 020_create_subscription_table.sql

-- 2. Migrate existing data/schema
\i 011_migrate_company_to_timestamptz.sql
\i 012_migrate_company_varchar_to_text.sql
\i 013_add_company_password_hash.sql
\i 014_add_company_password_reset.sql

-- 3. Drop and recreate functions with correct signatures
\i 009_drop_company_functions.sql
\i 010_create_company_functions.sql

-- 4. Schema cleanup (stripe_customer_id only in payment_method)
\i 019_drop_company_stripe_customer_id.sql

-- 5. Trial expiration notification tracking (EPIC-0-006-003)
\i 021_add_trial_notification_tracking.sql

-- 6. Trial-to-paid conversion function (EPIC-0-006-004)
\i 022_add_trial_conversion_function.sql

-- 7. Trial suspension function (EPIC-0-006-005)
\i 023_add_trial_suspension_function.sql

-- 8. Company profile schema (EPIC-0-007-001)
\i 024_add_company_profile_columns.sql
\i 025_create_location_table.sql
\i 026_create_location_functions.sql
\i 027_add_company_profile_functions.sql
\i 028_add_company_name.sql
\i 030_fix_company_get_profile.sql

-- 9. User/Role/Permission schema (EPIC-0-008-001)
\i 031_add_user_role_permission_schema.sql

-- 10. Migrate employee to user, drop employee table
\i 032_migrate_employee_to_user_drop_employee.sql

-- 11. User password invite (employee set-password flow)
\i 036_add_user_password_invite.sql

-- 11. Multi-location: Add location_id to inventory_item (EPIC-1-001)
\i 033_add_inventory_item_location_id.sql

-- 12. Rename game -> game_encyclopedia, inventory_item -> game_inventory
\i 034_rename_game_to_game_encyclopedia_inventory_to_game_inventory.sql

-- 13. Add company slug for path-based login (/{slug}/login)
\i 035_add_company_slug.sql

-- 14. Reserved slugs: avoid conflicts with system routes
\i 037_reserved_company_slugs.sql

-- 15. User invitation_expired status
\i 038_add_invitation_expired_status.sql

-- 16. Revamp built-in role permissions
\i 039_revamp_builtin_role_permissions.sql

-- 17. One role per user
\i 040_one_role_per_user.sql

-- 18. Customer portal user type + nullable customer email
\i 041_customer_portal_user_and_nullable_customer_email.sql

-- 19. Fix sale table missing subtotal/tax/total columns (idempotent)
\i 042_fix_sale_missing_columns.sql

-- 20. Fix sale_item table missing total_price column (idempotent)
\i 043_fix_sale_item_missing_columns.sql

-- 21. Give sale.total_amount a DEFAULT 0 so INSERTs without it succeed
\i 044_fix_sale_total_amount_default.sql

-- 22. Consignment tables
\i 045_create_consignment_tables.sql

-- 23. Seed consignment permissions for system roles
\i 046_seed_consignment_permissions.sql

-- 24. Promotion table with type, scope, and date range support
\i 055_create_promotion_table.sql

-- 25. Seed promotion permissions for system roles
\i 056_seed_promotion_permissions.sql

-- 26. Align consignment schema with acceptance criteria (status values, company_id index, FK ON DELETE)
\i 057_align_consignment_schema.sql

-- 27. Trade-in tables (TradeIns and TradeInItems)
\i 048_create_trade_in_tables.sql

-- 28. Seed trade-in permissions for system roles
\i 049_seed_trade_in_permissions.sql

-- 29. Make trade-in payment_type nullable
\i 050_make_trade_in_payment_type_nullable.sql

-- 30. Align trade-in permissions with acceptance criteria (remove trade_in.complete from Employee)
\i 058_align_trade_in_permissions.sql

-- 31. Add company_country column and update profile get/update functions (Issue #308)
\i 060_add_company_country.sql

-- Deployment complete
SELECT 'Database schema and functions created successfully!' AS status;
