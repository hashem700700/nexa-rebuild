-- ============================================================================
-- 02_rls_policies.sql
-- ============================================================================
-- 1. الغرض المعماري:
--    تطبيق سياسات عزل الأسطر (Row-Level Security - RLS) كخط حماية نهائي ومستقل
--    في مستوى قاعدة البيانات لمنع تسرب البيانات بين مستأجري النظام الباقيين.
--
-- 2. الثابت الذي يفرضه (Formal Invariant):
--    Invariant-TenantIsolation-02: ∀ Table T ∈ TenantScopedTables, 
--    ∀ Row R ∈ T, R.tenant_id = get_current_tenant_id().
--    تمنع هذه السياسة قراءة أو تعديل الأسطر التي لا تتطابق مع هوية الجلسة الموثقة.
--
-- 3. القيود التقنية المطبقة:
--    - فرض التفعيل المباشر (FORCE ROW LEVEL SECURITY) لتجنب تجاوز السياسات عند استخدام مالك الجدول.
--    - ربط مباشر بين تعبير السياسة ودالة التحقق get_current_tenant_id().
--
-- 4. أي استثناءات أو افتراضات:
--    - تفترض السياسة أن مستخدم الاتصال بالتطبيق (application_user) لا يمتلك صلاحية SUPERUSER
--      وإلا تجاوز سياسات RLS تلقائياً (لهذا يُفرض الهيكل ألا يتصل التطبيق بحساب سوبر).
-- ============================================================================

-- جدول الحسابات التوضيحي (Scoped Chart of Accounts for Demo)
CREATE TABLE IF NOT EXISTS accounts_ledger (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES system_tenants(tenant_id),
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uniq_tenant_account_code UNIQUE(tenant_id, account_code)
);

-- 1. تفعيل سياسة RLS على الجدول
ALTER TABLE accounts_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts_ledger FORCE ROW LEVEL SECURITY;

-- 2. صياغة السياسة الأمنية المعزولة للعمليات (ALL Operations Policy)
CREATE POLICY tenant_isolation_policy ON accounts_ledger
    FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());
