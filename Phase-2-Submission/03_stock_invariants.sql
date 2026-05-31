-- ============================================================================
-- 03_stock_invariants.sql
-- الغرض المعماري: فرض أرصدة المخزون الموجبة وحماية السجلات من التغيير الاعتباطي.
-- الثوابت: INV-STOCK-NEVER-NEG, INV-OP-IMMUTABILITY
-- ============================================================================

ALTER TABLE inventory_stock_levels 
ADD CONSTRAINT chk_stock_never_negative CHECK (quantity_on_hand >= 0);

CREATE OR REPLACE FUNCTION enforce_stock_movement_immutability() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'completed' AND NEW.status != 'reversed' THEN
        RAISE EXCEPTION 'OpImmutabilityViolation: Completed stock movements can only be reversed.' USING ERRCODE = 'I0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stock_movement_immutability
BEFORE UPDATE OR DELETE ON stock_movements
FOR EACH ROW EXECUTE FUNCTION enforce_stock_movement_immutability();
