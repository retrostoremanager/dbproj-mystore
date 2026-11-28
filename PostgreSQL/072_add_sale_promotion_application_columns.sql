-- Add the missing schema for promotions applied to a sale -- fn-mystore issue found
-- 2026-11-28. The promotion CATALOG table (055/060/064/067) shipped, but the columns and
-- table SalesRepository.CreateAsync/reads need to apply a promotion to an actual sale were
-- never migrated: sale.discount_total, sale_item.discount_amount/promotion_id/promotion_name,
-- and the sale_promotion table don't exist at all. Every checkout has always failed with
-- "column \"created_date\" of relation \"sale\" does not exist" (sale/sale_item also had an
-- unused, never-read created_date/subtotal reference in the INSERT, removed in the matching
-- fn-mystore fix rather than migrated, since nothing reads them).

ALTER TABLE sale ADD COLUMN IF NOT EXISTS discount_total DECIMAL(18, 2) NOT NULL DEFAULT 0;
COMMENT ON COLUMN sale.discount_total IS 'Total discount applied across all promotions on this sale.';

ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(18, 2) NOT NULL DEFAULT 0;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS promotion_id INTEGER;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS promotion_name VARCHAR(200);

ALTER TABLE sale_item DROP CONSTRAINT IF EXISTS fk_sale_item_promotion;
ALTER TABLE sale_item
    ADD CONSTRAINT fk_sale_item_promotion
    FOREIGN KEY (promotion_id) REFERENCES promotion(id) ON DELETE SET NULL;

COMMENT ON COLUMN sale_item.discount_amount IS 'Discount applied to this line item from a promotion.';
COMMENT ON COLUMN sale_item.promotion_id IS 'Promotion applied to this line item, if any. Nullable so deleting a promotion does not delete sale history.';
COMMENT ON COLUMN sale_item.promotion_name IS 'Snapshot of the promotion name at time of sale (survives promotion deletion/rename).';

CREATE TABLE IF NOT EXISTS sale_promotion (
    id              SERIAL PRIMARY KEY,
    sale_id         INTEGER NOT NULL,
    promotion_id    INTEGER,
    promotion_name  VARCHAR(200) NOT NULL,
    discount_amount DECIMAL(18, 2) NOT NULL,
    CONSTRAINT fk_sale_promotion_sale FOREIGN KEY (sale_id) REFERENCES sale(id) ON DELETE CASCADE,
    CONSTRAINT fk_sale_promotion_promotion FOREIGN KEY (promotion_id) REFERENCES promotion(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS ix_sale_promotion_sale_id ON sale_promotion(sale_id);

COMMENT ON TABLE sale_promotion IS 'Sale-level breakdown of promotions applied to a sale (one row per distinct promotion).';
COMMENT ON COLUMN sale_promotion.promotion_id IS 'Promotion applied, if any. Nullable so deleting a promotion does not delete sale history.';
COMMENT ON COLUMN sale_promotion.promotion_name IS 'Snapshot of the promotion name at time of sale.';
