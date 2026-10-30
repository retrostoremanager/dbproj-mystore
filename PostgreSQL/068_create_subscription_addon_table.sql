-- Create subscription_addon table for stacked Stripe subscription line items (e.g. Lot Scanner).
-- subscription keeps exactly one Stripe price per company (ix_subscription_stripe_id is
-- UNIQUE on stripe_subscription_id) -- a company's add-ons are additional items on that SAME
-- Stripe subscription, tracked here as child rows rather than bolting more nullable columns
-- onto subscription.
CREATE TABLE IF NOT EXISTS subscription_addon (
    id                              SERIAL PRIMARY KEY,
    subscription_id                 INT NOT NULL REFERENCES subscription(id) ON DELETE CASCADE,
    addon_type                      TEXT NOT NULL,
    stripe_subscription_item_id     TEXT NOT NULL,
    stripe_price_id                 TEXT NOT NULL,
    status                          TEXT NOT NULL,
    created_date                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date              TIMESTAMPTZ
);

-- One row per add-on type per subscription (e.g. a company can't subscribe to 'lot_scanner' twice).
CREATE UNIQUE INDEX IF NOT EXISTS ix_subscription_addon_sub_type ON subscription_addon(subscription_id, addon_type);

-- Index for looking up add-ons by subscription (webhook upsert path).
CREATE INDEX IF NOT EXISTS ix_subscription_addon_subscription_id ON subscription_addon(subscription_id);

COMMENT ON TABLE subscription_addon IS 'Add-on line items stacked on a company''s Stripe subscription (e.g. Lot Scanner). Updated via the same webhooks as subscription.';
COMMENT ON COLUMN subscription_addon.addon_type IS 'Add-on identifier, e.g. ''lot_scanner''. Matches a StripeOptions AddOnPriceId* mapping in fn-mystore.';

-- Not added to the RLS tenant_tables list in 061_enable_row_level_security.sql: like its
-- parent `subscription`, this table is written only by the anonymous Stripe webhook path,
-- which never sets app.current_company_id.
