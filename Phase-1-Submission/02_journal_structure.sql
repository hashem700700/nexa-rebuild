-- ============================================================================
-- 02_journal_structure.sql
-- الغرض المعماري: هيكل قيد اليومية (رأس + سطور) مع ميزة Reversal الآمن.
-- الثوابت: INV-IMMUTABLE, INV-REVERSAL
-- ============================================================================

CREATE TABLE IF NOT EXISTS journal_entries (
    journal_id UUID PRIMARY KEY, -- يُفترض توليده باستخدام H-UUID v7
    tenant_id UUID NOT NULL REFERENCES system_tenants(tenant_id),
    journal_number VARCHAR(50) NOT NULL,
    correlation_id UUID NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'posted', 'reversed')),
    reversal_of_journal_id UUID REFERENCES journal_entries(journal_id),
    posted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS journal_lines (
    line_id UUID PRIMARY KEY,
    journal_id UUID NOT NULL REFERENCES journal_entries(journal_id),
    account_id UUID NOT NULL, 
    amount_transaction_currency NUMERIC(18,4) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    fx_rate NUMERIC(18,6) NOT NULL DEFAULT 1.0,
    base_debit_amount NUMERIC(18,4) GENERATED ALWAYS AS (CASE WHEN amount_transaction_currency > 0 THEN amount_transaction_currency * fx_rate ELSE 0 END) STORED,
    base_credit_amount NUMERIC(18,4) GENERATED ALWAYS AS (CASE WHEN amount_transaction_currency < 0 THEN ABS(amount_transaction_currency * fx_rate) ELSE 0 END) STORED
);
