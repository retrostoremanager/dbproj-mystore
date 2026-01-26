-- Create Company table
CREATE TABLE IF NOT EXISTS company (
    id                          SERIAL PRIMARY KEY,
    email                       TEXT NOT NULL,
    status                      TEXT NOT NULL,
    trial_start_date            TIMESTAMPTZ NOT NULL,
    trial_end_date              TIMESTAMPTZ NOT NULL,
    verification_token          TEXT,
    verification_token_expires  TIMESTAMPTZ,
    subscription_tier           TEXT NOT NULL,
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
