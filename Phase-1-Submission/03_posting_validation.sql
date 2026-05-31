-- ============================================================================
-- 03_posting_validation.sql
-- الغرض المعماري: فرض التوازن المالي، ومنع التحويلات والحذف الخاطئ للقيود المعتمده
-- الثوابت: INV-DB-ENTRY, INV-IMMUTABLE
-- ============================================================================

CREATE OR REPLACE FUNCTION enforce_immutability() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'posted' THEN
        RAISE EXCEPTION 'ImmutableViolation: Cannot modify posted journal entries.' USING ERRCODE = 'F0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enforce_je_immutability
BEFORE UPDATE OR DELETE ON journal_entries
FOR EACH ROW EXECUTE FUNCTION enforce_immutability();

CREATE OR REPLACE FUNCTION enforce_journal_balance_and_transition() RETURNS TRIGGER AS $$
DECLARE
    total_debit NUMERIC(18,4);
    total_credit NUMERIC(18,4);
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.status = 'posted' AND OLD.status != 'draft' THEN
        RAISE EXCEPTION 'StateTransitionViolation: Journal can only be posted from draft status.' USING ERRCODE = 'F0005';
    END IF;

    IF NEW.status = 'posted' THEN
        SELECT COALESCE(SUM(base_debit_amount), 0), COALESCE(SUM(base_credit_amount), 0)
        INTO total_debit, total_credit
        FROM journal_lines WHERE journal_id = NEW.journal_id;

        IF total_debit != total_credit THEN
            RAISE EXCEPTION 'ImbalanceViolation: Journal is unbalanced. (Debit: %, Credit: %)', total_debit, total_credit USING ERRCODE = 'F0002';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enforce_journal_balance
BEFORE INSERT OR UPDATE ON journal_entries
FOR EACH ROW EXECUTE FUNCTION enforce_journal_balance_and_transition();
