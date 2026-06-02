-- Issue #278: Align trade-in permissions with acceptance criteria
-- Removes trade_in.complete from Employee role (Owner and Manager keep all three)
DELETE FROM role_permission
WHERE role_id IN (SELECT id FROM role WHERE company_id IS NULL AND name = 'Employee')
  AND permission_id IN (SELECT id FROM permission WHERE name = 'trade_in.complete');
