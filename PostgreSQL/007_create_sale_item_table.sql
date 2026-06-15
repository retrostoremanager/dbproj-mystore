-- Create SaleItem table
CREATE TABLE IF NOT EXISTS sale_item (
    id                  SERIAL PRIMARY KEY,
    sale_id             INTEGER NOT NULL,
    inventory_item_id   INTEGER NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          DECIMAL(18, 2) NOT NULL,
    total_price         DECIMAL(18, 2) NOT NULL,
    CONSTRAINT fk_sale_item_sale FOREIGN KEY (sale_id) REFERENCES sale(id) ON DELETE CASCADE,
    CONSTRAINT fk_sale_item_inventory_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_item(id)
);

-- Create index on sale_id
CREATE INDEX IF NOT EXISTS ix_sale_item_sale_id ON sale_item(sale_id);

-- Create index on inventory_item_id
CREATE INDEX IF NOT EXISTS ix_sale_item_inventory_item_id ON sale_item(inventory_item_id);

-- Add comment to table
COMMENT ON TABLE sale_item IS 'Stores individual items in a sale transaction';
