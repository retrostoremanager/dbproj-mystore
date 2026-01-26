# PostgreSQL Database Scripts

This directory contains PostgreSQL database migration scripts for the MyStore application.

## Files

- `000_deploy_all.sql` - Master deployment script that runs all migrations
- `001_create_company_table.sql` - Creates the company table
- `002_create_customer_table.sql` - Creates the customer table
- `003_create_employee_table.sql` - Creates the employee table
- `004_create_game_table.sql` - Creates the game table
- `005_create_inventory_item_table.sql` - Creates the inventory_item table
- `006_create_sale_table.sql` - Creates the sale table
- `007_create_sale_item_table.sql` - Creates the sale_item table
- `010_create_company_functions.sql` - Creates company-related functions

## Deployment

### Option 1: Deploy All (Recommended)

```bash
psql -h <server> -U <username> -d <database> -f 000_deploy_all.sql
```

### Option 2: Deploy Individual Scripts

Run each script in numerical order:

```bash
psql -h <server> -U <username> -d <database> -f 001_create_company_table.sql
psql -h <server> -U <username> -d <database> -f 002_create_customer_table.sql
# ... and so on
```

### Azure PostgreSQL Deployment

```bash
# Get connection string from Key Vault or deployment output
SERVER="mystore-postgres-dev.postgres.database.azure.com"
USERNAME="sqladmin"
DATABASE="mystore-db-dev"

# Deploy all scripts
psql "host=$SERVER port=5432 dbname=$DATABASE user=$USERNAME sslmode=require" -f 000_deploy_all.sql
```

## Key Differences from SQL Server

1. **Table Names**: Uses snake_case (e.g., `company`, `inventory_item`) instead of PascalCase
2. **Column Names**: Uses snake_case (e.g., `first_name`, `created_date`) instead of PascalCase
3. **Data Types**:
   - `NVARCHAR` → `VARCHAR` (PostgreSQL handles Unicode natively)
   - `DATETIME2` → `TIMESTAMP`
   - `BIT` → `BOOLEAN`
   - `IDENTITY` → `SERIAL`
   - `NVARCHAR(MAX)` → `TEXT`
4. **Functions**: Uses `CREATE OR REPLACE FUNCTION` instead of `CREATE PROCEDURE`
5. **Return Values**: Functions use `RETURNS TABLE` or `RETURNS INTEGER` instead of output parameters

## Multi-Tenancy

All tables (except `game` which is shared catalog) include a `company_id` column for multi-tenant support. The original SQL Server schema will need to be updated to match this pattern.

## Notes

- All scripts use `IF NOT EXISTS` to allow safe re-running
- Indexes are created with `IF NOT EXISTS` for idempotency
- Foreign key constraints ensure referential integrity
- Partial indexes are used for optional columns (e.g., verification_token)

## GitHub Actions

This repository uses GitHub Actions to automatically deploy database changes to Azure PostgreSQL when changes are pushed to the development branch.
