-- Seed consignment permissions and assign to default roles
-- Adds consignment.view and consignment.edit permissions

INSERT INTO permission (name, description) VALUES
    ('consignment.view', 'View consignment items and payouts'),
    ('consignment.edit', 'Create, edit, and manage consignment items and payouts')
ON CONFLICT (name) DO NOTHING;

-- Owner: all permissions (including new consignment permissions)
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Owner'
  AND p.name IN ('consignment.view', 'consignment.edit')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Manager: consignment.view and consignment.edit
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Manager'
  AND p.name IN ('consignment.view', 'consignment.edit')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Employee: consignment.view and consignment.edit
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Employee'
  AND p.name IN ('consignment.view', 'consignment.edit')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Cashier: consignment.view only
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Cashier'
  AND p.name IN ('consignment.view')
ON CONFLICT (role_id, permission_id) DO NOTHING;
