-- Rename game -> game_encyclopedia, inventory_item -> game_inventory
-- Separates game catalog from TCG cards (future: tcg_encyclopedia, tcg_inventory)

-- 1. Rename game table to game_encyclopedia
ALTER TABLE IF EXISTS game RENAME TO game_encyclopedia;

-- 2. Rename indexes on game_encyclopedia
ALTER INDEX IF EXISTS ix_game_title RENAME TO ix_game_encyclopedia_title;
ALTER INDEX IF EXISTS ix_game_console RENAME TO ix_game_encyclopedia_console;

-- 3. Rename inventory_item table to game_inventory (IF EXISTS for idempotency)
ALTER TABLE IF EXISTS inventory_item RENAME TO game_inventory;

-- 4. Rename FK constraint for consistency (FK auto-updates when game was renamed)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_inventory_item_game' AND table_name = 'game_inventory') THEN
        ALTER TABLE game_inventory RENAME CONSTRAINT fk_inventory_item_game TO fk_game_inventory_game_encyclopedia;
    END IF;
END $$;

-- 5. Rename indexes on game_inventory (IF EXISTS skips if index was created conditionally)
ALTER INDEX IF EXISTS ix_inventory_item_company_id RENAME TO ix_game_inventory_company_id;
ALTER INDEX IF EXISTS ix_inventory_item_game_id RENAME TO ix_game_inventory_game_id;
ALTER INDEX IF EXISTS ix_inventory_item_category RENAME TO ix_game_inventory_category;
ALTER INDEX IF EXISTS ix_inventory_item_name RENAME TO ix_game_inventory_name;
ALTER INDEX IF EXISTS ix_inventory_item_company_location RENAME TO ix_game_inventory_company_location;
ALTER INDEX IF EXISTS ix_inventory_item_location_id RENAME TO ix_game_inventory_location_id;

-- 6. Rename location FK constraint for consistency (if exists from 033)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_inventory_item_location' AND table_name = 'game_inventory') THEN
        ALTER TABLE game_inventory DROP CONSTRAINT fk_inventory_item_location;
        ALTER TABLE game_inventory ADD CONSTRAINT fk_game_inventory_location
            FOREIGN KEY (location_id) REFERENCES location(id) ON DELETE RESTRICT;
    END IF;
END $$;

-- 7. Rename sale_item FK to game_inventory (sale_item.inventory_item_id -> game_inventory.id)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_sale_item_inventory_item' AND table_name = 'sale_item') THEN
        ALTER TABLE sale_item RENAME CONSTRAINT fk_sale_item_inventory_item TO fk_sale_item_game_inventory;
    END IF;
END $$;

-- 8. Update table comments
COMMENT ON TABLE game_encyclopedia IS 'Video game catalog (encyclopedia). Separate from TCG cards.';
COMMENT ON TABLE game_inventory IS 'Game inventory items. Links to game_encyclopedia.';
