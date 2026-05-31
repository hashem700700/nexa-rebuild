-- ============================================================================
-- ملف: 01_saga_orchestrator_state.sql
-- ============================================================================
-- الغرض المعماري: تعريف آلة الحالة الموزعة (Saga State Machine) وتتبع مسار العمليات
-- التراكمية، مع ربط إلزامي بنواة الصلاحيات لضمان حوكمة التنفيذ لكل خطوة.
-- الثابت الذي يفرضه: INV-SAGA-STATE-MACHINE, INV-AUTHZ-SAGA-BIND
-- القيود التقنية: 
--  1. آلة حالة صارمة تمنع الانتقال العشوائي.
--  2. يُشترط وجود authz_decision_ref موثق لكل خطوة فعلية لضمان تفويض التنفيذ.
-- أي استثناءات أو افتراضات: لا توجد استثناءات. أي Saga يجب أن تخضع لنفس الآلة.
-- ============================================================================

CREATE TABLE IF NOT EXISTS saga_instances (
    saga_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    tenant_id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    saga_type VARCHAR(100) NOT NULL, -- e.g., 'Inventory-Accounting-Post'
    status VARCHAR(50) NOT NULL DEFAULT 'initiated' 
        CHECK (status IN ('initiated', 'executing', 'compensating', 'completed', 'failed')),
    previous_status VARCHAR(50), 
    -- Contract Note: Orchestrator validates (previous_status -> new_status) against Transition Matrix before UPDATE. DB enforces structural consistency only.
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_saga_correlation UNIQUE (tenant_id, correlation_id, saga_type)
);

CREATE TABLE IF NOT EXISTS saga_steps (
    step_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    saga_id UUID NOT NULL REFERENCES saga_instances(saga_id),
    step_order INT NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'compensated')),
    
    -- حزم الإجراءات والبيانات
    payload JSONB,
    compensation_payload JSONB,
    
    -- الارتباط الإلزامي بنواة التقييم الأمني قبل التنفيذ (INV-AUTHZ-SAGA-BIND)
    authz_decision_ref UUID NOT NULL,
    authz_decision_hash VARCHAR(64) NOT NULL,
    authz_verified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Contract Note: authz_decision_ref is a logical pointer. Validation occurs at Application Layer. DB stores audit trail only.
    
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_saga_step_order UNIQUE (saga_id, step_order)
);
