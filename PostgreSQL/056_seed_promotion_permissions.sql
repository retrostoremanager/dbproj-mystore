-- Issue #205: Promotions DB schema — seed promotion permissions
-- Assigns promotion.view to Owner, Manager, Employee
-- Assigns promotion.manage to Owner and Manager only

INSERT INTO permission (name, description) VALUES
    ('promotion.view',   'View promotions for the company'),
    ('promotion.manage', 'Create, edit, and manage promotions for the company')
ON CONFLICT (name) DO NOTHING;

-- Owner: promotion.view and promotion.manage
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Owner'
  AND p.name IN ('promotion.view', 'promotion.manage')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Manager: promotion.view and promotion.manage
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Manager'
  AND p.name IN ('promotion.view', 'promotion.manage')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Employee: promotion.view only
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Employee'
  AND p.name = 'promotion.view'
ON CONFLICT (role_id, permission_id) DO NOTHING;
