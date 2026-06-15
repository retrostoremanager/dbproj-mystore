# Agent Guidelines: SQL Server Database Project (DBProj)

## Critical First Step: Check for Existing Code

**BEFORE implementing any new functionality, you MUST:**
1. Review existing table definitions in the `Tables/` directory
2. Check `Schemas/` for existing schema definitions
3. Look for existing indexes, constraints, and relationships
4. Review existing naming conventions and patterns
5. Check for existing stored procedures, views, or functions
6. Verify foreign key relationships and referential integrity
7. **DO NOT reinvent the wheel** - reuse existing patterns, constraints, and index strategies

## Architecture Patterns

### Project Structure
- **Tables/**: Contains table definitions (one file per table)
- **Schemas/**: Contains schema definitions (e.g., `dbo.sql`)
- **MyStore.Database.sqlproj**: Database project file

### Naming Conventions
- **Tables**: PascalCase, singular (e.g., `Customer`, `InventoryItem`)
- **Columns**: PascalCase (e.g., `FirstName`, `CreatedDate`)
- **Indexes**: `IX_TableName_ColumnName` or `IX_TableName_Column1_Column2`
- **Primary Keys**: `PK_TableName`
- **Foreign Keys**: `FK_TableName_ReferencedTable`
- **Constraints**: Descriptive names (e.g., `CK_TableName_ColumnName_CheckName`)

## Coding Standards

### Table Definition Structure

```sql
CREATE TABLE [dbo].[TableName] (
    [Id]                INT            IDENTITY (1, 1) NOT NULL,
    [ColumnName]        NVARCHAR (100) NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [LastModifiedDate]  DATETIME2 (7)  NULL,
    CONSTRAINT [PK_TableName] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
```

### Primary Keys
- Use `INT IDENTITY (1, 1)` for primary keys
- Always create clustered primary key constraint
- Name constraint as `PK_TableName`
- Use `NOT NULL` for primary key columns

### Data Types
- **IDs**: `INT` for primary keys and foreign keys
- **Strings**: `NVARCHAR(n)` with appropriate length
- **Dates**: `DATETIME2 (7)` for date/time columns
- **Booleans**: `BIT` (0 = false, 1 = true)
- **Decimals**: `DECIMAL(p, s)` for monetary values
- **Text**: `NVARCHAR(MAX)` only when necessary

### Nullability
- Use `NOT NULL` for required fields
- Use `NULL` for optional fields
- Consider business rules when determining nullability
- Document nullable fields that might seem required

### Indexes

#### Primary Key Index
- Automatically created with PRIMARY KEY constraint
- Always clustered
- Named `PK_TableName`

#### Unique Indexes
- Create for columns that must be unique (e.g., Email)
- Use `UNIQUE NONCLUSTERED INDEX`
- Naming: `IX_TableName_ColumnName`

#### Non-Unique Indexes
- Create for frequently queried columns
- Create composite indexes for multi-column queries
- Use `NONCLUSTERED INDEX`
- Naming: `IX_TableName_ColumnName` or `IX_TableName_Column1_Column2`

#### Index Best Practices
- Index foreign key columns
- Index columns used in WHERE clauses
- Index columns used in JOIN conditions
- Consider composite indexes for multi-column queries
- Don't over-index (balance query performance vs. write performance)

### Foreign Keys
- Always define foreign key constraints for referential integrity
- Use `ON DELETE` and `ON UPDATE` actions appropriately:
  - `NO ACTION` or `CASCADE` based on business rules
  - `SET NULL` if the foreign key column is nullable
- Name foreign keys: `FK_TableName_ReferencedTable`
- Include foreign key columns in indexes

### Common Columns Pattern
- **Id**: Primary key (INT IDENTITY)
- **CreatedDate**: `DATETIME2 (7) NOT NULL` - when record was created
- **LastModifiedDate**: `DATETIME2 (7) NULL` - when record was last modified
- Consider adding audit columns if needed (CreatedBy, ModifiedBy)

### Constraints

#### Check Constraints
- Use for domain validation (e.g., positive values, valid ranges)
- Name: `CK_TableName_ColumnName_Description`

#### Default Constraints
- Use for default values (e.g., `GETUTCDATE()` for CreatedDate)
- Name: `DF_TableName_ColumnName`

### Multi-Tenancy Support
- If using company/organization isolation, include `CompanyId` column
- Create index on `CompanyId`
- Consider composite indexes with `CompanyId` + other columns
- Add foreign key to Company table if applicable

## Best Practices

### Table Design
1. **Normalization**: Follow 3NF (Third Normal Form) unless denormalization is needed for performance
2. **Consistency**: Follow existing patterns for similar tables
3. **Documentation**: Use comments to document complex business rules
4. **Naming**: Use clear, descriptive names
5. **Data Types**: Choose appropriate data types and sizes

### Index Strategy
1. **Primary Key**: Always clustered on ID column
2. **Foreign Keys**: Index all foreign key columns
3. **Query Patterns**: Index columns based on actual query patterns
4. **Composite Indexes**: Create for multi-column WHERE clauses
5. **Covering Indexes**: Consider including columns for query optimization

### Performance
1. **Appropriate Data Types**: Don't use larger types than needed
2. **Indexing**: Balance read vs. write performance
3. **Partitioning**: Consider for very large tables
4. **Computed Columns**: Use for frequently calculated values

### Security
1. **Principle of Least Privilege**: Grant minimum required permissions
2. **Schema Separation**: Use schemas to organize and secure objects
3. **Encryption**: Consider encryption for sensitive data
4. **Audit Columns**: Include audit columns for compliance

### Maintainability
1. **Consistent Patterns**: Follow existing table patterns
2. **Comments**: Document complex business rules
3. **Version Control**: Keep all scripts in version control
4. **Migration Scripts**: Create migration scripts for schema changes

## Common Patterns to Reuse

Before implementing new functionality, check for:
- Existing table definitions with similar structures
- Existing index patterns for similar use cases
- Existing foreign key relationship patterns
- Existing constraint patterns
- Existing naming conventions
- Existing common column patterns (CreatedDate, LastModifiedDate, etc.)

## Example: Adding a New Table

1. **Check existing tables**: Review similar tables for patterns
2. **Define Table**: Create table definition file in `Tables/` directory
3. **Primary Key**: Define clustered primary key on Id column
4. **Columns**: Add all columns with appropriate data types and nullability
5. **Indexes**: Create indexes for foreign keys and frequently queried columns
6. **Foreign Keys**: Define foreign key relationships
7. **Constraints**: Add check constraints and defaults as needed
8. **Test**: Verify table creation and relationships

## Example: Adding a Foreign Key Relationship

1. **Check existing relationships**: Review similar foreign key patterns
2. **Verify Referenced Table**: Ensure referenced table and column exist
3. **Add Foreign Key Column**: Add column to referencing table
4. **Create Index**: Index the foreign key column
5. **Add Constraint**: Create foreign key constraint with appropriate actions
6. **Test**: Verify referential integrity

## Example: Adding an Index

1. **Check existing indexes**: Review similar index patterns
2. **Analyze Query Patterns**: Understand how the table will be queried
3. **Create Index**: Add index definition after table definition
4. **Consider Composite**: Create composite index if multiple columns are queried together
5. **Test**: Verify index improves query performance

## Migration Considerations

- Always create migration scripts for production changes
- Test migrations on development/staging first
- Consider data migration for schema changes
- Document breaking changes
- Use transactions for atomic migrations
- Plan for rollback strategies

## Integration with Application Code

- Table names should match model class names (singular)
- Column names should match property names (PascalCase)
- Foreign key relationships should match navigation properties
- Consider application query patterns when designing indexes
- Ensure data types match between database and application models

