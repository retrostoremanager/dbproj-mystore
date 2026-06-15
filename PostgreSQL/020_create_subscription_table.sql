-- Create subscription table for storing Stripe subscription status
-- Tracks subscription state for billing and access control
CREATE TABLE IF NOT EXISTS subscription (
    id                          SERIAL PRIMARY KEY,
    company_id                  INT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    stripe_subscription_id      TEXT NOT NULL,
    stripe_customer_id          TEXT NOT NULL,
    stripe_price_id             TEXT,
    status                      TEXT NOT NULL,
    current_period_start        TIMESTAMPTZ,
    current_period_end          TIMESTAMPTZ,
    cancel_at_period_end        BOOLEAN NOT NULL DEFAULT false,
    created_date                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date          TIMESTAMPTZ
);

-- Unique constraint: one Stripe subscription per company (active)
CREATE UNIQUE INDEX IF NOT EXISTS ix_subscription_stripe_id ON subscription(stripe_subscription_id);

-- Index for looking up subscription by company
CREATE INDEX IF NOT EXISTS ix_subscription_company_id ON subscription(company_id);

-- Index for status queries (e.g., past_due, active)
CREATE INDEX IF NOT EXISTS ix_subscription_status ON subscription(status);

COMMENT ON TABLE subscription IS 'Stores Stripe subscription status for billing. Updated via webhooks.';
