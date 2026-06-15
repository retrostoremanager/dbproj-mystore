-- Migrate employee table to user table and drop employee.
-- sale.employee_id -> sale.user_id
-- user.employee_id removed (no longer references employee)

-- 1. Add phone to user (from employee)
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Migrate employees to users (create user records for employees that don't have one)
INSERT INTO "user" (company_id, email, first_name, last_name, user_type, phone, status)
SELECT e.company_id, e.email, e.first_name, e.last_name, 'employee', e.phone,
       CASE WHEN e.is_active THEN 'active' ELSE 'removed' END
FROM employee e
WHERE NOT EXISTS (SELECT 1 FROM "user" u WHERE u.company_id = e.company_id AND u.email = e.email);

-- 3. Assign roles to migrated users (map employee.role to system role)
INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id
FROM "user" u
JOIN employee e ON e.company_id = u.company_id AND e.email = u.email AND u.user_type = 'employee'
JOIN role r ON r.company_id IS NULL AND LOWER(r.name) = LOWER(e.role)
WHERE NOT EXISTS (SELECT 1 FROM user_role ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

-- 4. Add user_id to sale
ALTER TABLE sale ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- 5. Migrate sale.employee_id to sale.user_id (map via company_id + email)
UPDATE sale s
SET user_id = sub.u_id
FROM (
  SELECT s2.id AS sale_id, u.id AS u_id
  FROM sale s2
  JOIN employee e ON e.id = s2.employee_id
  JOIN "user" u ON u.company_id = e.company_id AND u.email = e.email
  WHERE s2.employee_id IS NOT NULL
) sub
WHERE s.id = sub.sale_id AND s.user_id IS NULL;

-- 6. Drop sale FK and employee_id column
ALTER TABLE sale DROP CONSTRAINT IF EXISTS fk_sale_employee;
ALTER TABLE sale DROP COLUMN IF EXISTS employee_id;

-- 7. Add sale FK to user
ALTER TABLE sale DROP CONSTRAINT IF EXISTS fk_sale_user;
ALTER TABLE sale ADD CONSTRAINT fk_sale_user FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS ix_sale_user_id ON sale(user_id);

-- 8. Drop user.employee_id FK and column
ALTER TABLE "user" DROP CONSTRAINT IF EXISTS fk_user_employee;
ALTER TABLE "user" DROP COLUMN IF EXISTS employee_id;
DROP INDEX IF EXISTS ix_user_employee_id;

-- 9. Drop employee table
DROP TABLE IF EXISTS employee;

COMMENT ON COLUMN sale.user_id IS 'User who processed the sale. Replaces employee_id.';
COMMENT ON COLUMN "user".phone IS 'Phone number (optional).';
