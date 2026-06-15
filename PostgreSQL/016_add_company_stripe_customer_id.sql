-- Add stripe_customer_id to company for subscription billing
ALTER TABLE company ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

COMMENT ON COLUMN company.stripe_customer_id IS 'Stripe customer ID for subscription billing. Created when first payment method is added.';
