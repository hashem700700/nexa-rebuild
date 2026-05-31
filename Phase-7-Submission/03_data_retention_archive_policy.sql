-- ============================================================================
-- ملف: 03_data_retention_archive_policy.sql
-- ============================================================================
-- الغرض المعماري: حوكمة دورة حياة البيانات من الحفظ الساخن (Hot) إلى الأرشفة (Cold) أو الحذف،
-- مع الاحتفاظ بالـ Audit Trail للامتثال القانوني.
-- الثابت الذي يفرضه: INV-RETENTION-LIFECYCLE
-- القيود التقنية: 
--  1. الأرشفة لا تكسر السجل المالي، بل تنقله لطبقة بطيئة دون تغيير الهاش.
--  2. الحذف (Purge) يقتصر على البيانات المعفية من الإلزام القانوني (PII بعد المدة)، ويسجل كفعل.
-- أي استثناءات أو افتراضات: النقل الفيزيائي للبيانات يُدار بـ Job خارجي، والـ DB توفر السجل فقط.
-- ============================================================================

CREATE TABLE IF NOT EXISTS data_retention_policies (
    policy_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    domain_entity VARCHAR(100) NOT NULL, -- e.g., 'journal_entries', 'gateway_request_audit'
    data_classification VARCHAR(30) NOT NULL CHECK (data_classification IN ('PERMANENT_IMMUTABLE', 'TIMEBOUND_ARCHIVABLE', 'PURGEABLE')),
    retention_period_days INT NOT NULL,  -- e.g., 3650 (10 سنوات للقيود المالية)
    action_after_period VARCHAR(20) NOT NULL CHECK (action_after_period IN ('archive', 'purge')),
    CONSTRAINT uq_tenant_retention_policy UNIQUE (tenant_id, domain_entity)
);

CREATE TABLE IF NOT EXISTS data_lifecycle_audit_log (
    log_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    tenant_id UUID NOT NULL,
    policy_id UUID REFERENCES data_retention_policies(policy_id),
    target_entity VARCHAR(100) NOT NULL,
    target_record_id UUID NOT NULL, -- الهوية الأصلية للسجل المؤرشف/المحذوف
    action_taken VARCHAR(20) NOT NULL CHECK (action_taken IN ('archived', 'purged')),
    execution_hash VARCHAR(64) NOT NULL, -- إثبات حالة السجل قبل التخلص منه
    executed_by_job VARCHAR(100) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Contract Note: This log is immutable. It proves that a record existed and was legally removed/archived.
