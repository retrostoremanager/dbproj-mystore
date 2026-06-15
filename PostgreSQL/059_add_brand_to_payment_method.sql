-- 059_add_brand_to_payment_method.sql
-- Adds the card brand column that PaymentRepository.CreateAsync writes to.
-- The application has always inserted brand (e.g. "visa"), but the column was
-- missing from 015_create_payment_method_table.sql, causing card-add to fail.

ALTER TABLE payment_method ADD COLUMN IF NOT EXISTS brand TEXT;
