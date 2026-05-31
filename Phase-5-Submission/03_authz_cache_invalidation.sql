-- ============================================================================
-- 03_authz_cache_invalidation.sql
-- الغرض المعماري: ضمان مزامنة وتحديث ذاكرة التخزين المؤقت للسياسات أمنياً عبر النظام الموزع.
-- الثابت: INV-AUTHZ-DECISION-CACHE, INV-OUTBOX-IDEMPOTENCY
-- القيود: التخزين يعتمد على نمط Outbox اللامتزامن مع قيد منع تكرار الإبطال.
-- ============================================================================

CREATE TABLE IF NOT EXISTS authz_invalidation_events (
    event_id UUID PRIMARY KEY, -- يتطلب UUID v7 كونه حدثاً زمنياً
    target_type VARCHAR(50) NOT NULL CHECK (target_type IN ('role', 'user', 'policy_rule')),
    target_id UUID NOT NULL,
    
    -- تطبيق الإجراء التصحيحي: إضافة العزل الجنائي Idempotency Key
    idempotency_key UUID NOT NULL,
    
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'published')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- تطبيق الإجراء التصحيحي: قيد رياضي يمنع الانبعاج عبر تكرار الإبطال غير المبرر
    CONSTRAINT uq_invalidation_idempotency UNIQUE (target_type, target_id, idempotency_key)
);
