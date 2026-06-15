-- Issue #205: Promotions DB schema — Promotions table with type, scope, and date range support

CREATE TABLE IF NOT EXISTS promotion (
    id              SERIAL PRIMARY KEY,
    company_id      INTEGER NOT NULL,
    name            VARCHAR(200) NOT NULL,
    type            VARCHAR(20) NOT NULL,
    discount_percent DECIMAL(5, 2),
    buy_quantity    INTEGER,
    get_quantity    INTEGER,
    scope           VARCHAR(20) NOT NULL,
    scope_value     VARCHAR(200),
    start_date      TIMESTAMPTZ NOT NULL,
    end_date        TIMESTAMPTZ,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_by      INTEGER NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_promotion_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE,
    CONSTRAINT fk_promotion_created_by FOREIGN KEY (created_by) REFERENCES "user"(id),
    CONSTRAINT chk_promotion_type CHECK (type IN ('percentage', 'bxgy')),
    CONSTRAINT chk_promotion_scope CHECK (scope IN ('store_wide', 'category', 'item'))
);

-- Index for active-promotions queries (company_id, is_active, start_date, end_date)
CREATE INDEX IF NOT EXISTS ix_promotion_company_active_dates
    ON promotion(company_id, is_active, start_date, end_date);

COMMENT ON TABLE promotion IS 'Promotional discounts scoped to store, category, or item with optional date ranges.';
COMMENT ON COLUMN promotion.type IS 'Promotion type: percentage (discount percent off) or bxgy (buy X get Y free).';
COMMENT ON COLUMN promotion.discount_percent IS 'Percentage discount (0–100). Used when type = percentage.';
COMMENT ON COLUMN promotion.buy_quantity IS 'Number of items customer must buy. Used when type = bxgy.';
COMMENT ON COLUMN promotion.get_quantity IS 'Number of items customer gets free. Used when type = bxgy.';
COMMENT ON COLUMN promotion.scope IS 'Scope of the promotion: store_wide, category, or item.';
COMMENT ON COLUMN promotion.scope_value IS 'Category name or inventory item id depending on scope. NULL for store_wide.';
COMMENT ON COLUMN promotion.start_date IS 'Date/time from which the promotion is valid.';
COMMENT ON COLUMN promotion.end_date IS 'Date/time at which the promotion expires. NULL means no expiry.';
COMMENT ON COLUMN promotion.is_active IS 'Whether the promotion is currently active.';
COMMENT ON COLUMN promotion.created_by IS 'User who created the promotion.';
