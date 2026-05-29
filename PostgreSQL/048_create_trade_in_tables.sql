-- Create trade_in table
CREATE TABLE IF NOT EXISTS trade_in (
    id                      SERIAL PRIMARY KEY,
    company_id              INTEGER NOT NULL,
    customer_id             INTEGER,
    status                  VARCHAR(50) NOT NULL DEFAULT 'draft',
    total_offered_value     DECIMAL(18, 2) NOT NULL DEFAULT 0,
    total_accepted_value    DECIMAL(18, 2),
    payment_type            VARCHAR(50) NOT NULL,
    notes                   TEXT,
    created_by              INTEGER NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at            TIMESTAMPTZ,
    CONSTRAINT fk_trade_in_company FOREIGN KEY (company_id) REFERENCES company(id),
    CONSTRAINT fk_trade_in_customer FOREIGN KEY (customer_id) REFERENCES customer(id),
    CONSTRAINT fk_trade_in_created_by FOREIGN KEY (created_by) REFERENCES "user"(id),
    CONSTRAINT chk_trade_in_status CHECK (status IN ('draft', 'completed', 'rejected')),
    CONSTRAINT chk_trade_in_payment_type CHECK (payment_type IN ('cash', 'store_credit')),
    CONSTRAINT chk_trade_in_total_offered_value CHECK (total_offered_value >= 0),
    CONSTRAINT chk_trade_in_total_accepted_value CHECK (total_accepted_value IS NULL OR total_accepted_value >= 0)
);

-- Index on (company_id, status) for list queries filtered by status
CREATE INDEX IF NOT EXISTS ix_trade_in_company_status ON trade_in(company_id, status);

-- Index on (company_id, created_at) for list queries sorted by date
CREATE INDEX IF NOT EXISTS ix_trade_in_company_created_at ON trade_in(company_id, created_at);

-- Index on customer_id for customer-scoped lookups
CREATE INDEX IF NOT EXISTS ix_trade_in_customer_id ON trade_in(customer_id);

COMMENT ON TABLE trade_in IS 'Records trade-in transactions where customers exchange items for cash or store credit';
COMMENT ON COLUMN trade_in.status IS 'Workflow status: draft (in progress), completed (accepted), rejected (declined)';
COMMENT ON COLUMN trade_in.payment_type IS 'How the customer is compensated: cash or store_credit';
COMMENT ON COLUMN trade_in.total_offered_value IS 'Sum of all offered values for items in this trade-in';
COMMENT ON COLUMN trade_in.total_accepted_value IS 'Final accepted value (set when trade-in is completed)';

-- Create trade_in_item table
CREATE TABLE IF NOT EXISTS trade_in_item (
    id                  SERIAL PRIMARY KEY,
    trade_in_id         INTEGER NOT NULL,
    game_title          VARCHAR(500) NOT NULL,
    platform            VARCHAR(100) NOT NULL,
    condition           VARCHAR(50) NOT NULL,
    offered_value       DECIMAL(18, 2) NOT NULL,
    accepted_value      DECIMAL(18, 2),
    inventory_item_id   INTEGER,
    parsed_by_ai        BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_trade_in_item_trade_in FOREIGN KEY (trade_in_id) REFERENCES trade_in(id) ON DELETE CASCADE,
    CONSTRAINT fk_trade_in_item_inventory_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_item(id),
    CONSTRAINT chk_trade_in_item_condition CHECK (condition IN ('poor', 'fair', 'good', 'excellent')),
    CONSTRAINT chk_trade_in_item_offered_value CHECK (offered_value >= 0),
    CONSTRAINT chk_trade_in_item_accepted_value CHECK (accepted_value IS NULL OR accepted_value >= 0)
);

-- Index on trade_in_id for item lookups by trade-in
CREATE INDEX IF NOT EXISTS ix_trade_in_item_trade_in_id ON trade_in_item(trade_in_id);

COMMENT ON TABLE trade_in_item IS 'Individual items within a trade-in transaction';
COMMENT ON COLUMN trade_in_item.condition IS 'Physical condition of the item: poor, fair, good, or excellent';
COMMENT ON COLUMN trade_in_item.offered_value IS 'Value offered to the customer for this item';
COMMENT ON COLUMN trade_in_item.accepted_value IS 'Final accepted value for this item (set when trade-in is completed)';
COMMENT ON COLUMN trade_in_item.inventory_item_id IS 'Optional link to an inventory item if this trade-in item was added to inventory';
COMMENT ON COLUMN trade_in_item.parsed_by_ai IS 'Whether the item details were parsed/populated by AI';
