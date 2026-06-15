-- Remove stripe_customer_id from company - it belongs only in payment_method
-- Each company's Stripe customer ID is stored with their payment methods
ALTER TABLE company DROP COLUMN IF EXISTS stripe_customer_id;
