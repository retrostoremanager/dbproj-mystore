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
