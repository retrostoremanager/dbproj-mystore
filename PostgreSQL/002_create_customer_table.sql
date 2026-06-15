-- Create Customer table
CREATE TABLE IF NOT EXISTS customer (
    id                  SERIAL PRIMARY KEY,
    company_id          INTEGER NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    phone               VARCHAR(20),
    address             VARCHAR(255),
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip_code            VARCHAR(10),
    created_date        TIMESTAMP NOT NULL,
    last_modified_date  TIMESTAMP,
    CONSTRAINT fk_customer_company FOREIGN KEY (company_id) REFERENCES company(id)
);

-- Create unique index on email per company
CREATE UNIQUE INDEX IF NOT EXISTS ix_customer_company_email 
    ON customer(company_id, email);

-- Create index on company_id
CREATE INDEX IF NOT EXISTS ix_customer_company_id ON customer(company_id);

-- Create index on last_name and first_name
CREATE INDEX IF NOT EXISTS ix_customer_last_name_first_name 
    ON customer(last_name, first_name);

-- Add comment to table
COMMENT ON TABLE customer IS 'Stores customer information';
