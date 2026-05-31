-- ============================================================================
-- 02_projection_idempotency.sql
-- الغرض المعماري: ضمان معالجة إسقاطات القراءة مرة واحدة فقط (Exactly-Once).
-- الثوابت: INV-PROJ-IDEMPOTENCY
-- ============================================================================

CREATE TABLE IF NOT EXISTS projection_idempotency_log (
    tenant_id UUID NOT NULL,
    target_projection VARCHAR(100) NOT NULL,
    event_id UUID NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_proj_event UNIQUE (tenant_id, target_projection, event_id)
);
