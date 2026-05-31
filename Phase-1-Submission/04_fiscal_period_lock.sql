-- ============================================================================
-- 04_fiscal_period_lock.sql
-- الغرض المعماري: ضمان عدم تسجيل قيود لفترات منتهية ومنع تداخل الفترات.
-- الثوابت: INV-PERIOD-LOCK
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE TABLE IF NOT EXISTS fiscal_periods (
    period_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    period_status VARCHAR(20) NOT NULL CHECK (period_status IN ('open', 'soft_locked', 'hard_locked', 'closed')),
    CONSTRAINT uq_tenant_period_nono_overlap EXCLUDE USING gist (
        tenant_id WITH =,
        daterange(start_date, end_date, '[]') WITH &&
    )
);

CREATE OR REPLACE FUNCTION enforce_fiscal_period_lock() RETURNS TRIGGER AS $$
DECLARE
    t_status VARCHAR(20);
BEGIN
    IF NEW.status = 'posted' THEN
        SELECT period_status INTO t_status FROM fiscal_periods
        WHERE tenant_id = NEW.tenant_id AND (NEW.posted_at::DATE BETWEEN start_date AND end_date) LIMIT 1;
        
        IF t_status IS NULL THEN
            RAISE EXCEPTION 'PeriodViolation: No defined fiscal period exists.' USING ERRCODE = 'F0003';
        END IF;
        IF t_status IN ('soft_locked', 'hard_locked', 'closed') THEN
            RAISE EXCEPTION 'PeriodViolation: Fiscal period is locked/closed (%).', t_status USING ERRCODE = 'F0004';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_fiscal_period_lock
BEFORE INSERT OR UPDATE ON journal_entries
FOR EACH ROW EXECUTE FUNCTION enforce_fiscal_period_lock();
