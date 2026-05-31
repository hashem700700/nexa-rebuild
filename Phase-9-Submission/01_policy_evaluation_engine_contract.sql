-- ============================================================================
-- ملف: 01_policy_evaluation_engine_contract.sql
-- ============================================================================
-- الغرض المعماري: إدارة سجلات تقييم محرك السياسات (Policy Engine) لضمان حتمية
-- التنفيذ، تحديد الحدود الزمنية، والتدقيق الجنائي لأي قرار يُتخذ بواسطة المحرك.
-- الثابت الذي يفرضه: INV-POLICY-ENGINE-EXEC
-- القيود التقنية: محرك السياسات هو من ينفذ القواعد. هذا الجدول هو The Audit Sink.
-- أي قرار تنفيذي يجب أن يكون حتمياً ومسجلاً بالكامل لمنع الغموض (Blackbox Avoidance).
-- ============================================================================

CREATE TABLE IF NOT EXISTS policy_evaluation_logs (
    evaluation_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    tenant_id UUID NOT NULL,
    policy_domain VARCHAR(100) NOT NULL, -- e.g., 'authz', 'retention', 'data_residency'
    rule_reference VARCHAR(255) NOT NULL,
    
    -- قيود الحتمية (INV-POLICY-ENGINE-EXEC)
    input_context_hash VARCHAR(64) NOT NULL, -- إثبات حالة الـ Context عند التقييم
    decision_outcome VARCHAR(50) NOT NULL CHECK (decision_outcome IN ('ALLOW', 'DENY', 'MITIGATED', 'ESCALATED', 'BYPASSED')),
    reasoning_code VARCHAR(100) NOT NULL,
    
    -- قيد الزمن المحدود للمحرك (TimeBounded)
    execution_latency_ms INT NOT NULL,
    
    evaluated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Contract Note: Engine MUST append its decision here synchronously or via reliable outbox.
-- High latency (e.g., execution_latency_ms > 100) triggers a Risk Escalation implicitly.
