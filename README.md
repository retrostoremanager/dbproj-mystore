# dbproj-mystore

SQL Server Database Project for MyStore application.

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

## Building and Deploying

This is a SQL Server Database Project (.sqlproj) that can be built and deployed using:
- Visual Studio
- SQL Server Data Tools (SSDT)
- Azure Data Studio with SQL Database Projects extension
- MSBuild command line

To build:
```
msbuild MyStore.Database.sqlproj
```

To publish, use the publish profile or deploy directly from Visual Studio.
