# dbproj-mystore — PostgreSQL Database Migrations

## Efficiency Rules (READ FIRST)

1. **Never run Glob, LS, or Find.** The full migration list is below — use it.
2. **Read each file at most once per session.**
3. **Before writing any SQL:** read the relevant existing migration files to confirm exact column names and types.
4. **Before your first tool call:** write a one-sentence plan: which files you will read and why.

## Migration Files (PostgreSQL/ directory, development branch)

- `001` — company
- `002` — customer
- `004` — game_encyclopedia
- `005` — game_inventory / inventory_item
- `006` — sale (subtotal, tax, total, payment_method, sale_date, notes)
- `007` — sale_item (sale_id, inventory_item_id, quantity, unit_price, total_price)
- `015` — payment_method
- `020` — subscription
- `025` — location
- `031` — user, role, permission, role_permission, user_role
- `033` — inventory_item.location_id
- `034` — rename game → game_encyclopedia, inventory → game_inventory
- `045` — consignment_items, consignment_payouts

To read a migration file:
```bash
GH_TOKEN="$GH_DISPATCH_TOKEN" gh api \
  "repos/retrostoremanager/dbproj-mystore/contents/PostgreSQL/<filename>?ref=development" \
  --jq '.content' | base64 -d
```

## SQL Conventions

- **File naming:** `NNN_short_description.sql` (next sequential number after the latest)
- **PostgreSQL only** — use `IF NOT EXISTS`, no `GO` statements, no `IDENTITY`
- **Primary keys:** `SERIAL` or `BIGSERIAL`
- **Timestamps:** `TIMESTAMP NOT NULL DEFAULT NOW()` for `created_at`/`updated_at`
- **Monetary columns:** `DECIMAL(18,2)` with `CHECK (column >= 0)` constraint
- **Status columns:** `VARCHAR(50)` with `CHECK (column IN ('val1','val2',...))` constraint
- **Percentage/split columns:** `DECIMAL(5,2)` with `CHECK (column >= 0 AND column <= 100)`
- **Indexes:** always add `(company_id)` and `(company_id, status)` on tenant-scoped tables
- **Foreign keys:** always explicit with `REFERENCES table(column) ON DELETE CASCADE/RESTRICT`
- **Idempotent:** wrap in `DO $$ BEGIN ... EXCEPTION WHEN duplicate_object THEN NULL; END $$` or use `IF NOT EXISTS`

## When Opening PRs

- Branch: `feature/issue-N` off `development`
- Target: `development` branch
- PR body must include: `Closes retrostoremanager/orchestrator-mystore#N`

**NEVER push directly to `development`.**