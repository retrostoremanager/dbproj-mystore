#!/bin/bash
# Deploy PostgreSQL Schema to Azure

SERVER="mystore-postgres-dev.postgres.database.azure.com"
DATABASE="mystore-db-dev"
USERNAME="sqladmin"
PASSWORD="MySecureDevPW\$1"

echo "========================================="
echo "Deploying PostgreSQL Schema"
echo "========================================="
echo ""

# Set password environment variable
export PGPASSWORD="$PASSWORD"

# Download the SQL files from GitHub
echo "Fetching schema files from GitHub..."

# Create temp directory
mkdir -p /tmp/dbdeploy
cd /tmp/dbdeploy

# Download each SQL file
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/001_create_company_table.sql -o 001.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/002_create_customer_table.sql -o 002.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/003_create_employee_table.sql -o 003.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/004_create_game_table.sql -o 004.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/005_create_inventory_item_table.sql -o 005.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/006_create_sale_table.sql -o 006.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/007_create_sale_item_table.sql -o 007.sql
curl -s https://raw.githubusercontent.com/sbranham314/dbproj-mystore/development/PostgreSQL/010_create_company_functions.sql -o 010.sql

echo ""
echo "Running SQL files..."

# Execute each SQL file
for sqlfile in *.sql; do
    echo "Executing: $sqlfile"
    psql "host=$SERVER port=5432 dbname=$DATABASE user=$USERNAME password=$PASSWORD sslmode=require" -f "$sqlfile"
    
    if [ $? -eq 0 ]; then
        echo "✓ $sqlfile completed successfully"
    else
        echo "✗ $sqlfile failed"
        exit 1
    fi
    echo ""
done

echo "========================================="
echo "Schema deployment completed!"
echo "========================================="

# Cleanup
cd ..
rm -rf /tmp/dbdeploy
