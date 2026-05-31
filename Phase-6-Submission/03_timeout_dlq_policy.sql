-- ============================================================================
-- ملف: 03_timeout_dlq_policy.sql
-- ============================================================================
-- الغرض المعماري: حاوية الأمان النهائية للحركات المعلقة أو العمليات المتوقفة زمنياً.
-- الثابت الذي يفرضه: INV-NO-HANGING-TX
-- القيود التقنية: أي عملية تتجاوز عتبة الـ Timeout Threshold يجب أن تعزل كرسائل ميتة (DLQ)،
-- ولن تُترك في حالة Hanging.
-- أي استثناءات أو افتراضات: استئناف الحركات من الـ DLQ يحتاج Correlation ID متطابق 
-- وينتج عنه محاولة جديدة (Replay) بـ Request Identity جديد.
-- ============================================================================

CREATE TABLE IF NOT EXISTS saga_timeout_policies (
    policy_id UUID PRIMARY KEY,
    saga_type VARCHAR(100) NOT NULL UNIQUE,
    global_timeout_seconds INT NOT NULL DEFAULT 300,
    step_timeout_seconds INT NOT NULL DEFAULT 60
);

CREATE TABLE IF NOT EXISTS dead_letter_queue (
    dlq_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    tenant_id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    saga_id UUID REFERENCES saga_instances(saga_id), -- قد يكون NULL إذا فشل قبل بدء الـ Saga
    source_type VARCHAR(100) NOT NULL, -- Event Bus, Gateway, Saga Step
    failed_payload JSONB,
    failure_reason TEXT NOT NULL,
    
    -- إضافات التتبع الزمني (INV-NO-HANGING-TX)
    deadline_at TIMESTAMP WITH TIME ZONE,
    timeout_detected_at TIMESTAMP WITH TIME ZONE,
    failure_origin VARCHAR(100) NOT NULL CHECK (failure_origin IN ('step_timeout', 'global_timeout', 'consumer_timeout', 'network_timeout', 'manual_escalation', 'business_rule_violation')),
    timeout_policy_ref UUID,
    
    -- حوكمة معالجة التعليقات
    retry_count INT NOT NULL DEFAULT 0,
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_by UUID, -- Auditor Identity
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- قيد زمني لضمان عدم وجود تناقض بين موعد انتهاء المهلة وتاريخ الاكتشاف
    CONSTRAINT chk_dlq_traceability CHECK (timeout_detected_at >= deadline_at OR failure_origin NOT IN ('step_timeout', 'global_timeout', 'consumer_timeout', 'network_timeout'))
    -- Contract Note: Orchestrator populates deadline_at from policy. Relayer sets timeout_detected_at on threshold breach.
);
