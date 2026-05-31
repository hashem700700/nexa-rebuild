-- ============================================================================
-- 04_bitemporal_setup.sql
-- ============================================================================
-- 1. الغرض المعماري:
--    تأسيس حوكمة وتتبع القيود والبيانات بالزمن الثنائي (Bitemporal Tracking)
--    لمنع حدوث تاليف أو تزوير بأثر رجعي للفترات المالية السابقة ومتابعة التعديلات الفنية.
--
-- 2. الثابت الذي يفرضه (Formal Invariant):
--    Invariant-BitemporalConsistency-01: ∀ Record R, 
--    (R.valid_to >= R.valid_from) ∧ (R.system_to >= R.system_from)
--    حيث يُمثّل الأول فترة الفعالية المعنوية للواقعة (Valid Time)،
--    ويُمثّل الثاني وعاء التسجيل الحسي للتعديل في جدول النظام الداخلي (System Time).
--
-- 3. القيود التقنية المطبقة:
--    - استخدام نطاقات الوقت المعيارية TIMESTAMP WITH TIME ZONE لتجنب مشاكل فوارق التوقيت الإقليمية.
--    - حقول زمن النظام تتم إدارتها تلقائياً عبر محرّر قاعدة البيانات أو مشغّر معتمد يمنع التدخل الخارجي.
--
-- 4. أي استثناءات أو افتراضات:
--    - يُفترض استخدام حزم النطاقات المفتوحة للأبد عبر ضبط تاريخ نهاية افتراضي بعيد جداً (مثل '9999-12-31').
-- ============================================================================

-- جدول توضيحي لفرض الزمن الثنائي على مستوى أرصدة الجرد المالي (Demo Bitemporal Revaluation Assets Table)
CREATE TABLE IF NOT EXISTS asset_valuations_bitemporal (
    asset_id UUID NOT NULL,
    tenant_id UUID NOT NULL REFERENCES system_tenants(tenant_id),
    valuation_value NUMERIC(18,4) NOT NULL,
    
    -- حقول زمن الصلاحية وسيقان الأعمال (Valid Time Range)
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT '9999-12-31 23:59:59+00',
    
    -- حقول زمن النظام والتعديل (System/Transaction Time Range)
    system_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    system_to TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT '9999-12-31 23:59:59+00',
    
    PRIMARY KEY (asset_id, tenant_id, valid_from, system_from)
);

-- فحص تداخل البيانات وتكامل الحدود الزمنية (Bitemporal Range Constraint Trigger Check)
CREATE OR REPLACE FUNCTION verify_bitemporal_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.valid_to < NEW.valid_from THEN
        RAISE EXCEPTION 'RangeViolation: Valid time ranges intersect incorrectly (valid_to is prior to valid_from).'
            USING ERRCODE = 'D0002';
    END IF;
    
    IF NEW.system_to < NEW.system_from THEN
        RAISE EXCEPTION 'RangeViolation: System time ranges intersect incorrectly (system_to is prior to system_from).'
            USING ERRCODE = 'D0003';
    END IF;
    
    -- منع التداخل الزمني المادي والمنطقي لنفس الأصل تحت نفس المستأجر (Range Overlap Prevention)
    IF EXISTS (
        SELECT 1 
        FROM asset_valuations_bitemporal 
        WHERE asset_id = NEW.asset_id 
          AND tenant_id = NEW.tenant_id
          -- تجنب المقارنة الذاتية عند التحديث
          AND (TG_OP = 'INSERT' OR (asset_id != OLD.asset_id OR valid_from != OLD.valid_from OR system_from != OLD.system_from))
          -- تمثيل فحص تقاطع الفترات الزمنية للبيانات (Overlap logic)
          AND NEW.valid_from < valid_to 
          AND NEW.valid_to > valid_from
          AND NEW.system_from < system_to 
          AND NEW.system_to > system_from
    ) THEN
        RAISE EXCEPTION 'OverlappingBitemporalRange: An active timeline valuation overlap detected for the same asset entity.'
            USING ERRCODE = 'D0005';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دمج محدد الفحص بالجدول
CREATE OR REPLACE TRIGGER trg_verify_bitemporal_asset_range
    BEFORE INSERT OR UPDATE ON asset_valuations_bitemporal
    FOR EACH ROW
    EXECUTE FUNCTION verify_bitemporal_range();

-- تفعيل سياسات الـ RLS وعزل المستأجر للجدول الثنائي
ALTER TABLE asset_valuations_bitemporal ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_valuations_bitemporal FORCE ROW LEVEL SECURITY;

CREATE POLICY asset_bitemporal_tenant_isolation_policy ON asset_valuations_bitemporal
    FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());
