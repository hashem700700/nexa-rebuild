-- =========================
-- INV: RLS FINAL GATE
-- =========================

-- Enable RLS on core financial + inventory tables
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries FORCE ROW LEVEL SECURITY;

ALTER TABLE journal_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_lines FORCE ROW LEVEL SECURITY;

ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements FORCE ROW LEVEL SECURITY;

ALTER TABLE outbox_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE outbox_events FORCE ROW LEVEL SECURITY;

-- =========================
-- CORE POLICY: TENANT ISOLATION
-- =========================

CREATE POLICY journal_entries_tenant_isolation ON journal_entries
USING (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
)
WITH CHECK (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
);

CREATE POLICY journal_lines_tenant_isolation ON journal_lines
USING (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
)
WITH CHECK (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
);

CREATE POLICY stock_movements_tenant_isolation ON stock_movements
USING (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
)
WITH CHECK (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
);

CREATE POLICY outbox_events_tenant_isolation ON outbox_events
USING (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
)
WITH CHECK (
  tenant_id = current_setting('app.current_tenant_id', true)::uuid
);
