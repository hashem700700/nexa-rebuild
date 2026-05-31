-- ============================================================================
-- 01_inventory_structure.sql
-- الغرض المعماري: نطاق المخازن، السجلات، مع إبقاء الـ Master Data كعقد مقروء فقط.
-- ============================================================================

-- يعتبر Contract من نظام MDM لضمان عدم تعديل البيانات الأساسية للنطاق المالي مباشرة 
CREATE TABLE IF NOT EXISTS item_master (
    item_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    item_code VARCHAR(50) NOT NULL
);
COMMENT ON TABLE item_master IS 'READ-ONLY CONTRACT (Owned by MDM Domain).';

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    warehouse_code VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS inventory_stock_levels (
    warehouse_id UUID NOT NULL,
    item_id UUID NOT NULL,
    quantity_on_hand NUMERIC(18,4) NOT NULL DEFAULT 0,
    PRIMARY KEY (warehouse_id, item_id)
);

CREATE TABLE IF NOT EXISTS stock_movements (
    movement_id UUID PRIMARY KEY, -- Identity UUID v7
    correlation_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    item_id UUID NOT NULL,
    quantity NUMERIC(18,4) NOT NULL,
    movement_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'reversed'))
);
