-- Issue #293: Fix fk_trade_in_item_inventory_item to reference game_inventory(id)
--
-- Migration 048 created trade_in_item with:
--     CONSTRAINT fk_trade_in_item_inventory_item
--         FOREIGN KEY (inventory_item_id) REFERENCES inventory_item(id)
--
-- Migration 034 had already renamed inventory_item -> game_inventory, so depending
-- on the order migrations were applied, this FK either:
--   * references a stale/legacy inventory_item relation, or
--   * was auto-updated to game_inventory but kept the misleading name.
--
-- Symptom: POST /api/trade-ins/{id}/complete fails on UpdateItemAsync with
--   23503: insert or update on table "trade_in_item" violates foreign key
--   constraint "fk_trade_in_item_inventory_item"
-- because InventoryRepository.CreateAsync inserts into game_inventory and returns
-- that row's id, which TradeInService.CompleteAsync then writes back to
-- trade_in_item.inventory_item_id.
--
-- This migration drops the existing FK (whatever it currently points at) and
-- re-adds it pointing at game_inventory(id) with the canonical constraint name
-- fk_trade_in_item_game_inventory, mirroring what migration 034 did for
-- sale_item's equivalent FK.
--
-- Idempotent and safe to run on top of 048_create_trade_in_tables.sql.

DO $$
BEGIN
    -- Drop the legacy FK if it still exists under either possible name.
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_trade_in_item_inventory_item'
          AND table_name = 'trade_in_item'
    ) THEN
        ALTER TABLE trade_in_item DROP CONSTRAINT fk_trade_in_item_inventory_item;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_trade_in_item_game_inventory'
          AND table_name = 'trade_in_item'
    ) THEN
        ALTER TABLE trade_in_item DROP CONSTRAINT fk_trade_in_item_game_inventory;
    END IF;

    -- Re-add the FK pointing at game_inventory(id) with the canonical name.
    ALTER TABLE trade_in_item
        ADD CONSTRAINT fk_trade_in_item_game_inventory
        FOREIGN KEY (inventory_item_id) REFERENCES game_inventory(id);
END $$;

COMMENT ON COLUMN trade_in_item.inventory_item_id IS
    'Optional link to a game_inventory row created when this trade-in item was added to inventory';
