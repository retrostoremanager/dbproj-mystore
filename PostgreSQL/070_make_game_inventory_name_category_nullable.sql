-- Make game_inventory.name/category nullable -- fn-mystore issue found 2026-11-28.
--
-- game_inventory (renamed from inventory_item in 034) still carries its original
-- name/category NOT NULL columns from 005, but the application has never populated
-- them since the 034 redesign: InventoryRepository derives Name/Category purely from
-- a LEFT JOIN to game_encyclopedia (COALESCE(g.title, ''), COALESCE(g.genre, '')) and
-- its own INSERT statement (and TradeInRepository's trade-in-completion insert) never
-- include name/category at all. Every attempt to create a new row has therefore always
-- failed with "null value in column \"name\" ... violates not-null constraint" --
-- masked until now by an unrelated column-name bug in the same INSERT statements.
--
-- These columns are effectively vestigial post-034 (never read back by the app either),
-- so this drops the NOT NULL constraints to match how the table is actually used,
-- rather than adding dead app-layer code to populate them.

ALTER TABLE game_inventory ALTER COLUMN name DROP NOT NULL;
ALTER TABLE game_inventory ALTER COLUMN category DROP NOT NULL;
