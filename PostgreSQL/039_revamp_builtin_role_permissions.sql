-- Revamp built-in role permissions per access requirements:
-- Owner: Full access to everything
-- Manager: All except subscription, billing, company profile
-- Employee: Inventory, sales, customers, trade-in, reports (no users, roles, billing, profile)
-- Cashier: Inventory (view), checkout, sales history, customers only

-- Update Manager: remove billing.view, billing.manage, settings.manage
DELETE FROM role_permission
WHERE role_id IN (SELECT id FROM role WHERE company_id IS NULL AND name = 'Manager')
  AND permission_id IN (SELECT id FROM permission WHERE name IN ('billing.view', 'billing.manage', 'settings.manage'));

-- Update Manager role description
UPDATE role SET description = 'Full access except subscription, billing, and company profile'
WHERE company_id IS NULL AND name = 'Manager';

-- Update Employee: remove users.*, billing.*, settings.manage; keep inventory, sales, customers, reports
DELETE FROM role_permission
WHERE role_id IN (SELECT id FROM role WHERE company_id IS NULL AND name = 'Employee');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Employee'
  AND p.name IN (
    'inventory.view', 'inventory.create', 'inventory.edit', 'inventory.delete',
    'sales.view', 'sales.create', 'sales.refund',
    'customers.view', 'customers.edit',
    'reports.view'
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Update Employee role description
UPDATE role SET description = 'Inventory, sales, customers, trade-in, and reports. No users, roles, billing, or profile.'
WHERE company_id IS NULL AND name = 'Employee';

-- Update Cashier: only inventory.view, sales.*, customers.*
DELETE FROM role_permission
WHERE role_id IN (SELECT id FROM role WHERE company_id IS NULL AND name = 'Cashier');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Cashier'
  AND p.name IN (
    'inventory.view',
    'sales.view', 'sales.create', 'sales.refund',
    'customers.view', 'customers.edit'
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Update Cashier role description
UPDATE role SET description = 'Inventory view, checkout, sales history, and customers only'
WHERE company_id IS NULL AND name = 'Cashier';
