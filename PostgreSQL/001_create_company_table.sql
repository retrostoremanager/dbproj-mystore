-- Create Company table
CREATE TABLE IF NOT EXISTS company (
    id                          SERIAL PRIMARY KEY,
    email                       VARCHAR(255) NOT NULL,
    status                      VARCHAR(50) NOT NULL,
    trial_start_date            TIMESTAMP NOT NULL,
    trial_end_date              TIMESTAMP NOT NULL,
    verification_token          VARCHAR(255),
    verification_token_expires  TIMESTAMP,
    subscription_tier           VARCHAR(50) NOT NULL,
    created_date                TIMESTAMP NOT NULL,
    last_modified_date          TIMESTAMP
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
