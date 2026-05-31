-- ============================================================================
-- 02_atomic_posting_wrapper.sql
-- الثوابت: INV-ATOMIC-CROSS, INV-OUTBOX-SYNC
-- الغرض المعماري: تمثيل الـ Distributed Transaction بتجريد محكم وتمرير idempotency_key صريح
-- ============================================================================

CREATE OR REPLACE FUNCTION execute_inventory_movement_and_post(
    p_tenant_id UUID,
    p_warehouse_id UUID,
    p_item_id UUID,
    p_quantity NUMERIC,
    p_correlation_id UUID,
    p_idempotency_key UUID
) RETURNS UUID AS $$
DECLARE
    v_movement_id UUID;
BEGIN
    -- Idempotency Protection BEFORE modifications
    IF EXISTS (SELECT 1 FROM outbox_events WHERE idempotency_key = p_idempotency_key::VARCHAR(255)) THEN
        RETURN p_correlation_id;
    END IF;

    v_movement_id := gen_random_uuid(); 

    INSERT INTO stock_movements (movement_id, correlation_id, tenant_id, warehouse_id, item_id, quantity, movement_type)
    VALUES (v_movement_id, p_correlation_id, p_tenant_id, p_warehouse_id, p_item_id, p_quantity, 'issue');

    INSERT INTO inventory_stock_levels (warehouse_id, item_id, quantity_on_hand)
    VALUES (p_warehouse_id, p_item_id, p_quantity)
    ON CONFLICT (warehouse_id, item_id) 
    DO UPDATE SET quantity_on_hand = inventory_stock_levels.quantity_on_hand + EXCLUDED.quantity_on_hand;

    -- الفرضية المعمارية (Fake Integration): سيقوم الاستدعاء بتنفيذ المحاسبة بشكل متزامن
    -- PERFORM accounting_api_post_journal(...);

    INSERT INTO outbox_events (event_id, tenant_id, correlation_id, idempotency_key, aggregate_type, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), p_tenant_id, p_correlation_id, p_idempotency_key::VARCHAR(255), 'Inventory', v_movement_id::TEXT, 'StockMoved', '{}');

    RETURN p_correlation_id;
END;
$$ LANGUAGE plpgsql;
