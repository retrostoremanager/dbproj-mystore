-- Create ConsignmentItems table
CREATE TABLE IF NOT EXISTS consignment_item (
    id              SERIAL PRIMARY KEY,
    company_id      INTEGER NOT NULL,
    customer_id     INTEGER NOT NULL,
    description     VARCHAR(500) NOT NULL,
    asking_price    DECIMAL(18, 2) NOT NULL,
    sale_price      DECIMAL(18, 2),
    split_percent   DECIMAL(5, 2) NOT NULL,
    status          VARCHAR(50) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ,
    CONSTRAINT fk_consignment_item_company FOREIGN KEY (company_id) REFERENCES company(id),
    CONSTRAINT fk_consignment_item_customer FOREIGN KEY (customer_id) REFERENCES customer(id)
);

-- Create index on (company_id, status) for efficient filtering
CREATE INDEX IF NOT EXISTS ix_consignment_item_company_status ON consignment_item(company_id, status);

-- Create index on customer_id
CREATE INDEX IF NOT EXISTS ix_consignment_item_customer_id ON consignment_item(customer_id);

-- Add comment to table
COMMENT ON TABLE consignment_item IS 'Stores items accepted from customers to sell on consignment';

-- Create ConsignmentPayouts table
CREATE TABLE IF NOT EXISTS consignment_payout (
    id                      SERIAL PRIMARY KEY,
    consignment_item_id     INTEGER NOT NULL,
    amount                  DECIMAL(18, 2) NOT NULL,
    paid_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes                   TEXT,
    CONSTRAINT fk_consignment_payout_item FOREIGN KEY (consignment_item_id) REFERENCES consignment_item(id)
);

-- Create index on consignment_item_id
CREATE INDEX IF NOT EXISTS ix_consignment_payout_item_id ON consignment_payout(consignment_item_id);

-- Add comment to table
COMMENT ON TABLE consignment_payout IS 'Records payout history when the store pays customers their share of a consignment sale';
