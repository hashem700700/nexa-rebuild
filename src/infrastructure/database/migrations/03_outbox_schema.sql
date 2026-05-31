-- ============================================================================
-- 03_outbox_schema.sql
-- ============================================================================
-- 1. الغرض المعماري:
--    تأصيل نمط صندوق الصادر المحلي (Transactional Outbox Pattern) لضمان اتساق
--    نشر الأحداث (Event Publishing) عبر النطاقات المختلفة دون الحاجة لمعاملات موزعة معقدة.
--
-- 2. الثابت الذي يفرضه (Formal Invariant):
--    Invariant-OutboxConsistency-01: StateChange(D) ⟺ RecordCreated(E) ∈ outbox_events
--    حيث يتم كتابة وحفظ الحدث في نفس وحدة العمل المعاملاتية (Local Database Transaction)
--    التي قامت بإحداث التغيير في بيانات النطاق المعني.
--
-- 3. القيود التقنية المطبقة:
--    - حقل البيانات (payload) يُحفظ بصيغة JSONB لدعم المرونة وتجنب تحجيم البيانات.
--    - تتبع رقم الإصدار المعرف للحدث (event_version) لدعم ترقية هياكل البيانات (Schema Evolution).
--    - مفتاح فريد لحالة المعالجة وتاريخ الإنتاج ومثبتات الفشل ومحاولات البث المتكررة.
--
-- 4. أي استثناءات أو افتراضات:
--    - لا يشمل صندوق الصادر العمليات الاستعلامية (Reads)، بل يقتصر على الحركات
--      المفرّزة للتغيير مادي للبيانات (CUD - Create, Update, Delete) ذات الأثر التشغيلي.
-- ============================================================================

-- جدول صندوق الصادر (Transactional Outbox Table)
CREATE TABLE IF NOT EXISTS outbox_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES system_tenants(tenant_id),
    correlation_id UUID NOT NULL,            -- الرقم الموحد لتتبع العمليات عابرة الحدود النطاقية
    idempotency_key VARCHAR(255) NOT NULL,   -- مفتاح التحصين الذي يضمن عدم التكرار على مستوى مستهلك الحدث
    aggregate_type VARCHAR(100) NOT NULL,    -- مثل 'JournalEntry', 'WarehouseStock'
    aggregate_id VARCHAR(100) NOT NULL,      -- المعرف الفريد للمجسم المنشئ
    event_type VARCHAR(100) NOT NULL,        -- مثل 'JournalEntryPosted', 'StockMovementRecorded'
    event_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    payload JSONB NOT NULL,                  -- بيانات الحدث التشغيلية الحرة
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processed', 'failed')),
    retry_count INT NOT NULL DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_outbox_idempotency UNIQUE (idempotency_key, tenant_id)
);

-- فهارس تسريع القراءة والاستعلام لعمال المزامنة (Outbox Relayers)
CREATE INDEX IF NOT EXISTS idx_outbox_pending_events 
ON outbox_events (status, created_at) 
WHERE status = 'pending';

-- تفعيل سياسات الـ RLS لحساب المستأجر لحماية الأحداث الصادرة من التسريب البيني
ALTER TABLE outbox_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE outbox_events FORCE ROW LEVEL SECURITY;

CREATE POLICY outbox_tenant_isolation_policy ON outbox_events
    FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());
