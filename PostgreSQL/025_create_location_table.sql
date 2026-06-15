-- EPIC-0-007-001: Location table for multi-location support
-- Business rule: At least one location must be created (enforced at application level)

CREATE TABLE IF NOT EXISTS location (
    id                  SERIAL PRIMARY KEY,
    company_id          INTEGER NOT NULL,
    name                TEXT NOT NULL,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    zip_code            TEXT,
    phone               TEXT,
    is_primary          BOOLEAN NOT NULL DEFAULT false,
    created_date        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date  TIMESTAMPTZ,
    CONSTRAINT fk_location_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_location_company_id ON location(company_id);
CREATE INDEX IF NOT EXISTS ix_location_is_primary ON location(company_id, is_primary) WHERE is_primary = true;

COMMENT ON TABLE location IS 'Store locations. Each company can have multiple locations.';
COMMENT ON COLUMN location.is_primary IS 'Primary/default location for the company. One per company.';
