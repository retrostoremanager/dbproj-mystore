-- Customer portal: allow user_type 'customer' for storefront logins (was owner|employee only).
-- Phone-only customers: allow NULL email; keep email unique per company when present.

ALTER TABLE "user" DROP CONSTRAINT IF EXISTS ck_user_type;
ALTER TABLE "user" ADD CONSTRAINT ck_user_type
    CHECK (user_type IN ('owner', 'employee', 'customer'));

COMMENT ON COLUMN "user".user_type IS
    'owner = company owner; employee = staff; customer = customer portal login.';

-- Legacy 002_create_customer_table had email NOT NULL; app allows phone-only rows.
ALTER TABLE customer ALTER COLUMN email DROP NOT NULL;

DROP INDEX IF EXISTS ix_customer_company_email;
CREATE UNIQUE INDEX IF NOT EXISTS ix_customer_company_email
    ON customer (company_id, email)
    WHERE email IS NOT NULL;
