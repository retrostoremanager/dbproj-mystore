-- Seed trade-in permissions and assign to default roles
-- Adds trade_in.create, trade_in.view, trade_in.complete permissions

INSERT INTO permission (name, description) VALUES
    ('trade_in.create', 'Create and manage trade-in transactions'),
    ('trade_in.view', 'View trade-in transactions and items'),
    ('trade_in.complete', 'Complete or reject trade-in transactions')
ON CONFLICT (name) DO NOTHING;

-- Owner: all trade-in permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Owner'
  AND p.name IN ('trade_in.create', 'trade_in.view', 'trade_in.complete')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Manager: all trade-in permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Manager'
  AND p.name IN ('trade_in.create', 'trade_in.view', 'trade_in.complete')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Employee: all trade-in permissions
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Employee'
  AND p.name IN ('trade_in.create', 'trade_in.view', 'trade_in.complete')
ON CONFLICT (role_id, permission_id) DO NOTHING;
