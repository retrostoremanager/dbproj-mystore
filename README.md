# dbproj-mystore

Database schema definitions for MyStore application.

## Deployment Status

✅ **Deployed to Azure** - The database schema is currently deployed on Azure Database for PostgreSQL Flexible Server.

## Project Structure

- **Tables/** - Contains all table definitions
  - `Customer.sql` - Customer information table
  - `Employee.sql` - Employee information table
  - `Game.sql` - Game reference data table
  - `InventoryItem.sql` - Inventory items table
  - `Sale.sql` - Sales transactions table
  - `SaleItem.sql` - Sale line items table

- **Schemas/** - Database schemas
  - `dbo.sql` - Default schema definition

## Database Schema

### Tables

1. **Customer** - Stores customer information
   - Primary Key: Id (Identity)
   - Unique Index: Email
   - Index: LastName, FirstName

2. **Employee** - Stores employee information
   - Primary Key: Id (Identity)
   - Unique Index: Email
   - Index: IsActive

3. **Game** - Stores game reference data
   - Primary Key: Id (NVARCHAR)
   - Indexes: Title, Console

4. **InventoryItem** - Stores inventory items
   - Primary Key: Id (Identity)
   - Foreign Key: GameId → Game.Id
   - Indexes: GameId, Category, Name
   - Completeness fields stored as boolean columns

5. **Sale** - Stores sales transactions
   - Primary Key: Id (Identity)
   - Foreign Keys: CustomerId → Customer.Id, EmployeeId → Employee.Id
   - Indexes: CustomerId, EmployeeId, SaleDate

6. **SaleItem** - Stores sale line items
   - Primary Key: Id (Identity)
   - Foreign Keys: SaleId → Sale.Id (CASCADE DELETE), InventoryItemId → InventoryItem.Id
   - Indexes: SaleId, InventoryItemId

## Database Platform

This project contains schema definitions for both:
- **SQL Server** (legacy, `.sqlproj` and `Tables/` directory)
- **PostgreSQL** (current, `PostgreSQL/` directory) ✅ **ACTIVE**

The application is currently using **Azure Database for PostgreSQL Flexible Server**.

## PostgreSQL Schema

The PostgreSQL schema files are located in the `PostgreSQL/` directory and include:
- Table creation scripts (numbered 001-007)
- Function definitions (010+)
- Complete deployment script (`000_deploy_all.sql`)

For PostgreSQL setup and deployment instructions, see `PostgreSQL/README.md`.

## SQL Server (Legacy)

The SQL Server Database Project (`.sqlproj`) files are maintained for reference but are not currently in use. The project can be built using:
- Visual Studio
- SQL Server Data Tools (SSDT)
- Azure Data Studio with SQL Database Projects extension
