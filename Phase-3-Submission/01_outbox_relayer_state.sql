-- ============================================================================
-- 01_outbox_relayer_state.sql
-- الغرض المعماري: إدارة الـ Cursors لمتلقي الأحداث المستقلين.
-- الثوابت: INV-RELAYER-CURSOR
-- ============================================================================

CREATE TABLE IF NOT EXISTS outbox_relayer_cursors (
    consumer_id VARCHAR(100) NOT NULL,
    tenant_id UUID NOT NULL,
    last_processed_event_id UUID NOT NULL, -- UUID v7
    processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (consumer_id, tenant_id)
);
