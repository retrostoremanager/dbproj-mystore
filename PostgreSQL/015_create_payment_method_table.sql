-- Create payment_method table for storing Stripe payment method references
-- Never stores full card numbers - only Stripe IDs and last 4 digits for display
CREATE TABLE IF NOT EXISTS payment_method (
    id                          SERIAL PRIMARY KEY,
    company_id                  INT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    stripe_customer_id           TEXT NOT NULL,
    stripe_payment_method_id     TEXT NOT NULL,
    last4                       VARCHAR(4) NOT NULL,
    expiration_month            INT NOT NULL,
    expiration_year             INT NOT NULL,
    is_default                  BOOLEAN NOT NULL DEFAULT false,
    created_date                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date          TIMESTAMPTZ
);

-- Index for looking up payment methods by company
CREATE INDEX IF NOT EXISTS ix_payment_method_company_id ON payment_method(company_id);

-- Unique constraint: one default per company
CREATE UNIQUE INDEX IF NOT EXISTS ix_payment_method_company_default
    ON payment_method(company_id)
    WHERE is_default = true;

COMMENT ON TABLE payment_method IS 'Stores Stripe payment method references for subscription billing. Never stores full card numbers.';
