-- ============================================================================
-- ملف: 02_compensation_registry.sql
-- ============================================================================
-- الغرض المعماري: تسجيل المعاملات التعويضية المضادة لضمان الحتمية الرياضية للخطوات العكسية 
-- عند الفشل الجزئي (Strict Reverse Compensation).
-- الثابت الذي يفرضه: INV-COMPENSATE-REVERSE
-- القيود التقنية: المعاملات التعويضية معرفة مسبقاً لكل خطوة، بترتيب عكسي صارم.
-- أي استثناءات أو افتراضات: العمليات العابرة لبيئات لا تدعم التراجع الآلي (التحويل البنكي الفعلي كمثال)
-- تُرحل إلى حالة المعالجة اليدوية (Manual Resolution) ضمن خصائص הـ Registry.
-- ============================================================================

CREATE TABLE IF NOT EXISTS saga_compensation_registry (
    registry_id UUID PRIMARY KEY,
    saga_type VARCHAR(100) NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    compensating_action VARCHAR(255) NOT NULL, -- e.g., 'Accounting.ReverseJournal'
    
    -- إضافة الترتيب العكسي الإلزامي
    reverse_compensation_order INT NOT NULL CHECK (reverse_compensation_order > 0),
    
    -- طبيعة التعويض وحوكمته
    requires_manual_resolution BOOLEAN NOT NULL DEFAULT false,
    retry_policy JSONB NOT NULL DEFAULT '{"max_retries": 3, "backoff_ms": 1000}',
    
    CONSTRAINT uq_compensation_reverse UNIQUE (saga_type, step_name, reverse_compensation_order)
    -- Contract Note: Orchestrator queries ordered by reverse_compensation_order DESC. Strict LIFO enforcement at runtime.
);
