-- PostgreSQL Database Setup Script for MyStore
-- Execute this script to create all tables and functions

-- Run migrations in order
\i 001_create_company_table.sql
\i 002_create_customer_table.sql
\i 003_create_employee_table.sql
\i 004_create_game_table.sql
\i 005_create_inventory_item_table.sql
\i 006_create_sale_table.sql
\i 007_create_sale_item_table.sql
\i 010_create_company_functions.sql
\i 011_migrate_company_to_timestamptz.sql

-- Deployment complete
SELECT 'Database schema and functions created successfully!' AS status;
