-- ============================================================================
-- 01_chart_of_accounts.sql
-- الغرض المعماري: تعريف دليل الحسابات الخاص بالمحاسبة كنطاق معزول.
-- ============================================================================

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES system_tenants(tenant_id),
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
    default_currency VARCHAR(3) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_account_code UNIQUE (tenant_id, account_code)
);
