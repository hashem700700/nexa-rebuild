-- =========================
-- INV: REFERENTIAL INTEGRITY (FINANCIAL BOUNDARY)
-- =========================

-- In a multi-tenant system, foreign keys should ideally include tenant_id
-- to prevent cross-tenant references masquerading as valid relationships.

-- 1. Ensure unique constraints exist for composite keys
ALTER TABLE chart_of_accounts DROP CONSTRAINT IF EXISTS chart_of_accounts_tenant_account_key;
ALTER TABLE chart_of_accounts ADD CONSTRAINT chart_of_accounts_tenant_account_key UNIQUE (tenant_id, account_id);

ALTER TABLE warehouses DROP CONSTRAINT IF EXISTS warehouses_tenant_warehouse_key;
ALTER TABLE warehouses ADD CONSTRAINT warehouses_tenant_warehouse_key UNIQUE (tenant_id, warehouse_id);

ALTER TABLE item_master DROP CONSTRAINT IF EXISTS item_master_tenant_item_key;
ALTER TABLE item_master ADD CONSTRAINT item_master_tenant_item_key UNIQUE (tenant_id, item_id);

ALTER TABLE journal_entries DROP CONSTRAINT IF EXISTS journal_entries_tenant_journal_key;
ALTER TABLE journal_entries ADD CONSTRAINT journal_entries_tenant_journal_key UNIQUE (tenant_id, journal_id);

-- 2. Apply Strict Composite Foreign Keys
ALTER TABLE journal_lines
  DROP CONSTRAINT IF EXISTS fk_jl_journal,
  DROP CONSTRAINT IF EXISTS fk_jl_account;

ALTER TABLE journal_lines
  ADD CONSTRAINT fk_jl_journal FOREIGN KEY (tenant_id, journal_id) REFERENCES journal_entries(tenant_id, journal_id),
  ADD CONSTRAINT fk_jl_account FOREIGN KEY (tenant_id, account_id) REFERENCES chart_of_accounts(tenant_id, account_id);

ALTER TABLE stock_movements
  DROP CONSTRAINT IF EXISTS fk_sm_warehouse,
  DROP CONSTRAINT IF EXISTS fk_sm_item;

ALTER TABLE stock_movements
  ADD CONSTRAINT fk_sm_warehouse FOREIGN KEY (tenant_id, warehouse_id) REFERENCES warehouses(tenant_id, warehouse_id),
  ADD CONSTRAINT fk_sm_item FOREIGN KEY (tenant_id, item_id) REFERENCES item_master(tenant_id, item_id);

-- =========================
-- INV: BITEMPORAL AUDITING (JOURNAL ENTRIES)
-- =========================
-- Add explicit temporal boundaries to track exactly when an entry became reality
ALTER TABLE journal_entries 
  ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP WITH TIME ZONE DEFAULT '9999-12-31 23:59:59+00';
