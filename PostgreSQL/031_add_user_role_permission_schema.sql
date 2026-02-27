-- EPIC-0-008-001: User Management Database Schema
-- Users, roles, and permissions with many-to-many relationships.
-- Users can have multiple roles. Roles can have multiple permissions.
-- Default (system) roles: Owner, Manager, Employee, Cashier - visible to all companies.
-- Custom roles: company_id NOT NULL - visible only to that company.

-- 1. Permission table (system-defined, shared across all companies)
CREATE TABLE IF NOT EXISTS permission (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    description     TEXT,
    created_date    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE permission IS 'System-defined permissions. Used by roles to grant access.';
COMMENT ON COLUMN permission.name IS 'Permission identifier (e.g. inventory.view, sales.create).';

-- 2. Role table (system roles: company_id NULL; custom roles: company_id NOT NULL)
CREATE TABLE IF NOT EXISTS role (
    id                  SERIAL PRIMARY KEY,
    name                TEXT NOT NULL,
    description         TEXT,
    company_id          INTEGER NULL,
    created_date        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date   TIMESTAMPTZ,
    CONSTRAINT fk_role_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_role_company_id ON role(company_id);
-- System roles (company_id NULL): unique name across all companies
CREATE UNIQUE INDEX IF NOT EXISTS ix_role_system_name ON role(name) WHERE company_id IS NULL;
-- Custom roles: unique name per company
CREATE UNIQUE INDEX IF NOT EXISTS ix_role_company_name ON role(company_id, name) WHERE company_id IS NOT NULL;

COMMENT ON TABLE role IS 'Roles assign permissions. System roles (company_id NULL) are default roles for all companies. Custom roles (company_id NOT NULL) are company-specific.';
COMMENT ON COLUMN role.company_id IS 'NULL = system/default role (visible to all companies). NOT NULL = custom role (visible only to that company).';

-- 3. Role-Permission junction (roles have many permissions)
CREATE TABLE IF NOT EXISTS role_permission (
    role_id         INTEGER NOT NULL,
    permission_id   INTEGER NOT NULL,
    created_date    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id) REFERENCES permission(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_role_permission_permission_id ON role_permission(permission_id);

COMMENT ON TABLE role_permission IS 'Many-to-many: roles have multiple permissions.';

-- 4. User table (unified: company owner + employees)
-- Company owner: user_type='owner', employee_id=NULL.
-- Employee: user_type='employee', employee_id=employee.id.
CREATE TABLE IF NOT EXISTS "user" (
    id                  SERIAL PRIMARY KEY,
    company_id          INTEGER NOT NULL,
    email               TEXT NOT NULL,
    first_name          TEXT NOT NULL,
    last_name           TEXT NOT NULL,
    user_type           TEXT NOT NULL DEFAULT 'employee',
    employee_id         INTEGER NULL,
    status              TEXT NOT NULL DEFAULT 'active',
    created_date        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date  TIMESTAMPTZ,
    CONSTRAINT fk_user_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_employee FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE SET NULL,
    CONSTRAINT uq_user_company_email UNIQUE (company_id, email),
    CONSTRAINT ck_user_type CHECK (user_type IN ('owner', 'employee')),
    CONSTRAINT ck_user_status CHECK (status IN ('pending_invitation', 'active', 'removed'))
);

CREATE INDEX IF NOT EXISTS ix_user_company_id ON "user"(company_id);
CREATE INDEX IF NOT EXISTS ix_user_employee_id ON "user"(employee_id) WHERE employee_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_user_status ON "user"(status);

COMMENT ON TABLE "user" IS 'Users who can access the system. Owner = company owner. Employee = linked to employee record.';
COMMENT ON COLUMN "user".user_type IS 'owner = company owner; employee = staff with employee record.';
COMMENT ON COLUMN "user".employee_id IS 'Links to employee when user_type=employee. NULL for owner.';
COMMENT ON COLUMN "user".status IS 'pending_invitation, active, or removed.';

-- 5. User-Role junction (users have many roles)
CREATE TABLE IF NOT EXISTS user_role (
    user_id         INTEGER NOT NULL,
    role_id         INTEGER NOT NULL,
    created_date    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_user_role_role_id ON user_role(role_id);

COMMENT ON TABLE user_role IS 'Many-to-many: users can have multiple roles.';

-- 6. Seed default permissions (idempotent)
INSERT INTO permission (name, description) VALUES
    ('inventory.view', 'View inventory items'),
    ('inventory.create', 'Create inventory items'),
    ('inventory.edit', 'Edit inventory items'),
    ('inventory.delete', 'Delete inventory items'),
    ('sales.view', 'View sales and transactions'),
    ('sales.create', 'Create sales/transactions'),
    ('sales.refund', 'Process refunds'),
    ('customers.view', 'View customer records'),
    ('customers.edit', 'Create and edit customers'),
    ('reports.view', 'View reports'),
    ('billing.view', 'View billing and subscription'),
    ('billing.manage', 'Manage billing and payment methods'),
    ('settings.manage', 'Manage company profile and settings'),
    ('users.view', 'View users and roles'),
    ('users.invite', 'Invite new users'),
    ('users.manage', 'Change user roles and permissions'),
    ('users.remove', 'Remove users from company')
ON CONFLICT (name) DO NOTHING;

-- 7. Seed default (system) roles - company_id NULL (visible to all companies)
INSERT INTO role (name, description, company_id)
SELECT v.name, v.description, v.company_id
FROM (VALUES
    ('Owner', 'Full access to all features including billing and user management', NULL::INTEGER),
    ('Manager', 'Most access except billing; can manage users and settings', NULL::INTEGER),
    ('Employee', 'Inventory and sales access', NULL::INTEGER),
    ('Cashier', 'Sales only', NULL::INTEGER)
) AS v(name, description, company_id)
WHERE NOT EXISTS (
    SELECT 1 FROM role r
    WHERE r.company_id IS NOT DISTINCT FROM v.company_id AND r.name = v.name
);

-- 8. Assign permissions to default roles
-- Owner: all permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Owner'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Manager: all except billing.manage
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Manager'
  AND p.name != 'billing.manage'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Employee: inventory and sales (no billing, settings, users)
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Employee'
  AND p.name IN ('inventory.view', 'inventory.create', 'inventory.edit', 'inventory.delete',
                 'sales.view', 'sales.create', 'sales.refund',
                 'customers.view', 'customers.edit', 'reports.view')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Cashier: sales and customers only
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Cashier'
  AND p.name IN ('sales.view', 'sales.create', 'sales.refund',
                 'customers.view', 'customers.edit', 'inventory.view')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 9. Create user records for existing company owners and assign Owner role (idempotent)
INSERT INTO "user" (company_id, email, first_name, last_name, user_type, employee_id, status)
SELECT c.id, c.email, 'Owner', '', 'owner', NULL, 'active'
FROM company c
WHERE NOT EXISTS (SELECT 1 FROM "user" u WHERE u.company_id = c.id AND u.email = c.email);

INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id
FROM "user" u
JOIN role r ON r.company_id IS NULL AND r.name = 'Owner'
WHERE u.user_type = 'owner'
  AND NOT EXISTS (SELECT 1 FROM user_role ur WHERE ur.user_id = u.id AND ur.role_id = r.id);
