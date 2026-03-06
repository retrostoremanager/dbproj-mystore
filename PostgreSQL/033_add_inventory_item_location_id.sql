-- EPIC-1-001: Multi-Location Database Schema - Add location_id to inventory_item
-- Business rule: Inventory items must belong to a location
-- Location names must be unique within a company

-- 1. Add unique constraint on location(company_id, name) - only if no duplicates exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM location
        GROUP BY company_id, name
        HAVING COUNT(*) > 1
    ) THEN
        ALTER TABLE location
        ADD CONSTRAINT uq_location_company_name UNIQUE (company_id, name);
    END IF;
EXCEPTION
    WHEN duplicate_object THEN NULL; -- Constraint already exists
END $$;

-- 2. Add location_id column to inventory_item (nullable for migration)
ALTER TABLE inventory_item
ADD COLUMN IF NOT EXISTS location_id INTEGER;

-- 3. Backfill: Set location_id for existing inventory items
-- Use primary location, or first location if no primary
UPDATE inventory_item ii
SET location_id = (
    SELECT l.id
    FROM location l
    WHERE l.company_id = ii.company_id
    ORDER BY l.is_primary DESC NULLS LAST, l.id
    LIMIT 1
)
WHERE ii.location_id IS NULL
  AND EXISTS (SELECT 1 FROM location l WHERE l.company_id = ii.company_id);

-- 4. For companies with no locations: create default location (business rule: each company must have at least one)
INSERT INTO location (company_id, name, is_primary, created_date)
SELECT DISTINCT ii.company_id, 'Default Location', true, NOW()
FROM inventory_item ii
WHERE ii.location_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM location l WHERE l.company_id = ii.company_id);

-- 5. Retry backfill for any remaining (companies that had no location, now have one)
UPDATE inventory_item ii
SET location_id = (
    SELECT l.id
    FROM location l
    WHERE l.company_id = ii.company_id
    ORDER BY l.is_primary DESC NULLS LAST, l.id
    LIMIT 1
)
WHERE ii.location_id IS NULL;

-- 6. Make location_id NOT NULL and add foreign key
ALTER TABLE inventory_item
ALTER COLUMN location_id SET NOT NULL;

ALTER TABLE inventory_item
ADD CONSTRAINT fk_inventory_item_location
FOREIGN KEY (location_id) REFERENCES location(id) ON DELETE RESTRICT;

-- 7. Create composite index for (company_id, location_id) - performance for location-based queries
CREATE INDEX IF NOT EXISTS ix_inventory_item_company_location
ON inventory_item(company_id, location_id);

-- 8. Create index on location_id for FK lookups
CREATE INDEX IF NOT EXISTS ix_inventory_item_location_id
ON inventory_item(location_id);

COMMENT ON COLUMN inventory_item.location_id IS 'Location where this inventory item is stored. EPIC-1-001.';
