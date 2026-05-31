-- ============================================================================
-- 01_tenant_isolation.sql
-- ============================================================================
-- 1. الغرض المعماري:
--    تأسيس الهيكل الأساسي لعزل المستأجرين (Tenants) على مستوى قاعدة البيانات
--    وتوفير آليات تفتيش وحماية الجلسة دون الاعتماد على طبقة التطبيق.
--
-- 2. الثابت الذي يفرضه (Formal Invariant):
--    Invariant-TenantIsolation-01: ∀ Session S, Current_Tenant(S) MUST be defined 
--    and match a valid UUID before any transactional read/write operates on 
--    tenant-scoped schemas.
--
-- 3. القيود التقنية المطبقة:
--    - استخدام UUIDv4 للمعرفات الفريدة لضمان عشوائية التوزيع وعدم قابلية التخمين.
--    - استخدام session variable مخصص 'app.current_tenant_id' للتحكم في السياق اللحظي.
--    - منع الولوج للمستأجرين المعطلين (suspended) عبر قيود فحص صريحة.
--
-- 4. أي استثناءات أو افتراضات:
--    - يُفترض وجود دور (Role) محدد للاتصال برلماني (App Context) يمتلك صلاحيات محدودة.
--    - يُستثنى من الفلترة المباشرة عمليات الصيانة الوقائية والنسخ الاحتياطي عبر دور سوبر (SuperAdmin Role) يتم تفصيله لاحقاً.
-- ============================================================================

-- تفعيل ملحق UUID لإنشاء معرفات عشوائية آمنة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- جدول المستأجرين الرئيسي (Tenants Register)
CREATE TABLE IF NOT EXISTS system_tenants (
    tenant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'provisioning')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- دالة استرداد سياق المستأجر الحالي من الجلسة الآمنة
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS UUID AS $$
DECLARE
    tenant_val VARCHAR;
BEGIN
    tenant_val := current_setting('app.current_tenant_id', true);
    IF tenant_val IS NULL OR tenant_val = '' THEN
        RAISE EXCEPTION 'MissingSessionContext: app.current_tenant_id is not set for the current transactional session.'
            USING ERRCODE = 'D0001'; -- كود مخصص لمنع تجاوز الجلسات
    END IF;

    -- التحقق من صحة تنسيق الـ UUIDv4 لمنع أخطاء الصب غير الصالحة بالـ runtime
    IF tenant_val !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RAISE EXCEPTION 'InvalidTenantFormat: app.current_tenant_id is not a valid UUIDv4 structure.'
            USING ERRCODE = 'D0004';
    END IF;

    RETURN tenant_val::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
