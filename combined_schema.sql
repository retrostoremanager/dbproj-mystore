-- Create Company table
CREATE TABLE IF NOT EXISTS company (
    id                          SERIAL PRIMARY KEY,
    email                       VARCHAR(255) NOT NULL,
    status                      VARCHAR(50) NOT NULL,
    trial_start_date            TIMESTAMPTZ NOT NULL,
    trial_end_date              TIMESTAMPTZ NOT NULL,
    verification_token          VARCHAR(255),
    verification_token_expires  TIMESTAMPTZ,
    subscription_tier           VARCHAR(50) NOT NULL,
    created_date                TIMESTAMPTZ NOT NULL,
    last_modified_date          TIMESTAMPTZ
);

-- Create unique index on email
CREATE UNIQUE INDEX IF NOT EXISTS ix_company_email ON company(email);

-- Create index on status
CREATE INDEX IF NOT EXISTS ix_company_status ON company(status);

-- Create partial index on verification_token (only non-null values)
CREATE INDEX IF NOT EXISTS ix_company_verification_token 
    ON company(verification_token) 
    WHERE verification_token IS NOT NULL;

-- Add comment to table
COMMENT ON TABLE company IS 'Stores company/organization information for multi-tenant support';
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
-- Create Employee table
CREATE TABLE IF NOT EXISTS employee (
    id                  SERIAL PRIMARY KEY,
    company_id          INTEGER NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    phone               VARCHAR(20),
    role                VARCHAR(50) NOT NULL,
    hire_date           TIMESTAMP NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_date        TIMESTAMP NOT NULL,
    last_modified_date  TIMESTAMP,
    CONSTRAINT fk_employee_company FOREIGN KEY (company_id) REFERENCES company(id)
);

-- Create unique index on email per company
CREATE UNIQUE INDEX IF NOT EXISTS ix_employee_company_email 
    ON employee(company_id, email);

-- Create index on company_id
CREATE INDEX IF NOT EXISTS ix_employee_company_id ON employee(company_id);

-- Create index on is_active
CREATE INDEX IF NOT EXISTS ix_employee_is_active ON employee(is_active);

-- Add comment to table
COMMENT ON TABLE employee IS 'Stores employee information';
-- Create Game table
CREATE TABLE IF NOT EXISTS game (
    id            VARCHAR(100) PRIMARY KEY,
    title         VARCHAR(255) NOT NULL,
    console       VARCHAR(100) NOT NULL,
    release_date  DATE,
    publisher     VARCHAR(255),
    genre         VARCHAR(100),
    image_url     VARCHAR(500)
);

-- Create index on title
CREATE INDEX IF NOT EXISTS ix_game_title ON game(title);

-- Create index on console
CREATE INDEX IF NOT EXISTS ix_game_console ON game(console);

-- Add comment to table
COMMENT ON TABLE game IS 'Stores video game catalog information';
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

-- Create index on category
CREATE INDEX IF NOT EXISTS ix_inventory_item_category ON inventory_item(category);

-- Create index on name
CREATE INDEX IF NOT EXISTS ix_inventory_item_name ON inventory_item(name);

-- Add comment to table
COMMENT ON TABLE inventory_item IS 'Stores inventory items for sale';
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
-- Function: Get Company by ID
CREATE OR REPLACE FUNCTION company_get_by_id(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.id = p_id;
END;
$$;

-- Function: Get Company by Email
CREATE OR REPLACE FUNCTION company_get_by_email(p_email VARCHAR(255))
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.email = p_email;
END;
$$;

-- Function: Get Company by Verification Token
CREATE OR REPLACE FUNCTION company_get_by_verification_token(p_token VARCHAR(255))
RETURNS TABLE (
    id INTEGER,
    email VARCHAR(255),
    status VARCHAR(50),
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    verification_token VARCHAR(255),
    verification_token_expires TIMESTAMP,
    subscription_tier VARCHAR(50),
    created_date TIMESTAMP,
    last_modified_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.email, c.status, c.trial_start_date, c.trial_end_date,
           c.verification_token, c.verification_token_expires, c.subscription_tier,
           c.created_date, c.last_modified_date
    FROM company c
    WHERE c.verification_token = p_token;
END;
$$;

-- Function: Create Company
CREATE OR REPLACE FUNCTION company_create(
    p_email VARCHAR(255),
    p_status VARCHAR(50),
    p_trial_start_date TIMESTAMP,
    p_trial_end_date TIMESTAMP,
    p_verification_token VARCHAR(255) DEFAULT NULL,
    p_verification_token_expires TIMESTAMP DEFAULT NULL,
    p_subscription_tier VARCHAR(50),
    p_created_date TIMESTAMP,
    p_last_modified_date TIMESTAMP DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO company (
        email, status, trial_start_date, trial_end_date,
        verification_token, verification_token_expires, subscription_tier,
        created_date, last_modified_date
    )
    VALUES (
        p_email, p_status, p_trial_start_date, p_trial_end_date,
        p_verification_token, p_verification_token_expires, p_subscription_tier,
        p_created_date, p_last_modified_date
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

-- Function: Update Company
CREATE OR REPLACE FUNCTION company_update(
    p_id INTEGER,
    p_email VARCHAR(255),
    p_status VARCHAR(50),
    p_trial_start_date TIMESTAMP,
    p_trial_end_date TIMESTAMP,
    p_verification_token VARCHAR(255) DEFAULT NULL,
    p_verification_token_expires TIMESTAMP DEFAULT NULL,
    p_subscription_tier VARCHAR(50),
    p_last_modified_date TIMESTAMP DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE company
    SET email = p_email,
        status = p_status,
        trial_start_date = p_trial_start_date,
        trial_end_date = p_trial_end_date,
        verification_token = p_verification_token,
        verification_token_expires = p_verification_token_expires,
        subscription_tier = p_subscription_tier,
        last_modified_date = p_last_modified_date
    WHERE id = p_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RETURN v_rows_affected;
END;
$$;
