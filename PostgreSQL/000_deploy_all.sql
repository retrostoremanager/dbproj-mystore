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

-- Deployment complete
SELECT 'Database schema and functions created successfully!' AS status;
