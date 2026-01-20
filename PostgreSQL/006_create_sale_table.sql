-- Create Sale table
CREATE TABLE IF NOT EXISTS sale (
    id              SERIAL PRIMARY KEY,
    company_id      INTEGER NOT NULL,
    customer_id     INTEGER NOT NULL,
    employee_id     INTEGER,
    subtotal        DECIMAL(18, 2) NOT NULL,
    tax             DECIMAL(18, 2) NOT NULL,
    total           DECIMAL(18, 2) NOT NULL,
    payment_method  VARCHAR(50) NOT NULL,
    sale_date       TIMESTAMP NOT NULL,
    notes           TEXT,
    CONSTRAINT fk_sale_company FOREIGN KEY (company_id) REFERENCES company(id),
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES customer(id),
    CONSTRAINT fk_sale_employee FOREIGN KEY (employee_id) REFERENCES employee(id)
);

-- Create index on company_id
CREATE INDEX IF NOT EXISTS ix_sale_company_id ON sale(company_id);

-- Create index on customer_id
CREATE INDEX IF NOT EXISTS ix_sale_customer_id ON sale(customer_id);

-- Create index on employee_id
CREATE INDEX IF NOT EXISTS ix_sale_employee_id ON sale(employee_id);

-- Create index on sale_date (descending for recent sales first)
CREATE INDEX IF NOT EXISTS ix_sale_sale_date ON sale(sale_date DESC);

-- Add comment to table
COMMENT ON TABLE sale IS 'Stores sales transactions';
