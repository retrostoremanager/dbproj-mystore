-- Issue #185: Loyalty endpoints — seed loyalty.manage permission
-- Assigns loyalty.manage to Owner and Manager roles

INSERT INTO permission (name, description) VALUES
    ('loyalty.manage', 'Manage loyalty programme settings for the company')
ON CONFLICT (name) DO NOTHING;

-- Owner: loyalty.manage
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Owner'
  AND p.name = 'loyalty.manage'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Manager: loyalty.manage
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r CROSS JOIN permission p
WHERE r.company_id IS NULL AND r.name = 'Manager'
  AND p.name = 'loyalty.manage'
ON CONFLICT (role_id, permission_id) DO NOTHING;
