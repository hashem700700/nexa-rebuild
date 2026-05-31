-- ============================================================================
-- 03_read_models_schema.sql
-- الغرض المعماري: نماذج قراءة المخزون مفصولة بوضوح وبأنواع هوية صحيحة (UUID).
-- الثوابت: INV-READ-ONLY-DOMAIN
-- ============================================================================

CREATE TABLE IF NOT EXISTS projection_inventory_stock (
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    item_id UUID NOT NULL,
    calculated_quantity NUMERIC(18,4) NOT NULL DEFAULT 0,
    last_updated_by_event UUID NOT NULL,
    fiscal_period VARCHAR(20),
    PRIMARY KEY (tenant_id, warehouse_id, item_id)
);
