-- Backfill the Owner "user"/user_role rows that every company registered since migration
-- 031_add_user_role_permission_schema.sql has been missing. That migration's one-time backfill
-- only covered companies that existed when it ran; nothing in CompanyService.RegisterAsync ever
-- replicated it for new registrations (fixed separately in fn-mystore), so every company that
-- signed up after 031 could log in but failed every [RequirePermission] check (billing,
-- inventory, users -- everything). Same shape as 031's backfill, re-run here because it's fully
-- idempotent (NOT EXISTS guards) and scoped to whatever is still missing today. Column list
-- excludes employee_id (dropped by 032_migrate_employee_to_user_drop_employee.sql, after 031
-- originally ran).

INSERT INTO "user" (company_id, email, first_name, last_name, user_type, status)
SELECT c.id, c.email, 'Owner', '', 'owner', 'active'
FROM company c
WHERE NOT EXISTS (SELECT 1 FROM "user" u WHERE u.company_id = c.id AND u.email = c.email);

INSERT INTO user_role (user_id, role_id)
SELECT u.id, r.id
FROM "user" u
JOIN role r ON r.company_id IS NULL AND r.name = 'Owner'
WHERE u.user_type = 'owner'
  AND NOT EXISTS (SELECT 1 FROM user_role ur WHERE ur.user_id = u.id AND ur.role_id = r.id);
