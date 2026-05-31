-- =========================
-- INV: IMMUTABILITY LAYER
-- =========================

-- Journal Entries: No UPDATE/DELETE after posted
CREATE OR REPLACE FUNCTION enforce_journal_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'posted' THEN
    RAISE EXCEPTION 'F0001: IMMUTABLE_VIOLATION - Posted journal entries cannot be modified';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_journal_immutability
BEFORE UPDATE OR DELETE ON journal_entries
FOR EACH ROW
EXECUTE FUNCTION enforce_journal_immutability();

-- =========================
-- INV: DOUBLE ENTRY VALIDATION (DB SAFETY NET)
-- =========================

CREATE OR REPLACE FUNCTION enforce_double_entry_balance()
RETURNS TRIGGER AS $$
DECLARE
  debit_sum NUMERIC;
  credit_sum NUMERIC;
BEGIN
  SELECT COALESCE(SUM(debit_amount),0),
         COALESCE(SUM(credit_amount),0)
  INTO debit_sum, credit_sum
  FROM journal_lines
  WHERE journal_id = NEW.journal_id;

  IF debit_sum <> credit_sum THEN
    RAISE EXCEPTION 'F0002: UNBALANCED_ENTRY - Debit % != Credit %', debit_sum, credit_sum;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_double_entry_validation
AFTER INSERT OR UPDATE ON journal_entries
FOR EACH ROW
EXECUTE FUNCTION enforce_double_entry_balance();

-- =========================
-- INV: PROJECTION WRITE PROTECTION
-- =========================

CREATE OR REPLACE FUNCTION block_projection_writes()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'F0003: PROJECTION_READONLY - Direct writes are forbidden';
END;
$$ LANGUAGE plpgsql;

-- Example projection table protection
CREATE TRIGGER trg_block_inventory_projection_write
BEFORE INSERT OR UPDATE OR DELETE ON projection_inventory_stock
FOR EACH ROW
EXECUTE FUNCTION block_projection_writes();
