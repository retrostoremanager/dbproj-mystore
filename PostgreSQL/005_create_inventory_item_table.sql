-- Create InventoryItem table
CREATE TABLE IF NOT EXISTS inventory_item (
    id                  SERIAL PRIMARY KEY,
    company_id          INTEGER NOT NULL,
    name                VARCHAR(255) NOT NULL,
    category            VARCHAR(100) NOT NULL,
    quantity            INTEGER NOT NULL DEFAULT 0,
    sell_price          DECIMAL(18, 2) NOT NULL,
    buy_price           DECIMAL(18, 2),
    condition           VARCHAR(50) NOT NULL,
    game_id             VARCHAR(100),
    has_box             BOOLEAN NOT NULL DEFAULT false,
    has_instructions    BOOLEAN NOT NULL DEFAULT false,
    has_game            BOOLEAN NOT NULL DEFAULT true,
    has_inserts         BOOLEAN NOT NULL DEFAULT false,
    has_other           BOOLEAN NOT NULL DEFAULT false,
    notes               TEXT,
    added_date          TIMESTAMP NOT NULL,
    last_modified_date  TIMESTAMP,
    CONSTRAINT fk_inventory_item_company FOREIGN KEY (company_id) REFERENCES company(id),
    CONSTRAINT fk_inventory_item_game FOREIGN KEY (game_id) REFERENCES game(id)
);

-- Create index on company_id
CREATE INDEX IF NOT EXISTS ix_inventory_item_company_id ON inventory_item(company_id);

-- Create index on game_id
CREATE INDEX IF NOT EXISTS ix_inventory_item_game_id ON inventory_item(game_id);

-- Create indexes on category and name (conditional - skip if columns don't exist, e.g. different schema)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_item' AND column_name = 'category') THEN
    CREATE INDEX IF NOT EXISTS ix_inventory_item_category ON inventory_item(category);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_item' AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS ix_inventory_item_name ON inventory_item(name);
  END IF;
END $$;

-- Add comment to table
COMMENT ON TABLE inventory_item IS 'Stores inventory items for sale';
