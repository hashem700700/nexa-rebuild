-- ============================================================================
-- 02_sod_runtime_validator.sql
-- الغرض المعماري: تخزين مصفوفة تعارض الصلاحيات (SoD) وطلبات الوصول المؤقت الجبرية (JIT).
-- الثابت: INV-PRIVILEGE-BOUND, INV-JIT-ACCESS-ONLY
-- ============================================================================

-- مصفوفة التعارض (يُمنع منطقياً الجمع بين هذين الدورين لنفس المستخدم)
CREATE TABLE IF NOT EXISTS sod_conflict_matrix (
    conflict_id UUID PRIMARY KEY,
    role_a UUID NOT NULL,
    role_b UUID NOT NULL,
    conflict_description TEXT NOT NULL,
    
    -- إضافة Foreign Keys صريحة
    CONSTRAINT fk_role_a FOREIGN KEY (role_a) REFERENCES system_roles(role_id),
    CONSTRAINT fk_role_b FOREIGN KEY (role_b) REFERENCES system_roles(role_id),
    
    CONSTRAINT uq_sod_conflict UNIQUE (role_a, role_b)
);

-- نظام JIT (الوقت المحدد) للتجاوزات المعتمدة (يغلق ثغرة الـ Admin Bypass المطلق)
CREATE TABLE IF NOT EXISTS jit_access_requests (
    jit_request_id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    requested_role_id UUID NOT NULL,
    justification TEXT NOT NULL,
    approved_by UUID,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired', 'revoked')),
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    approval_chain JSONB,
    risk_tier VARCHAR(20) NOT NULL DEFAULT 'LOW',
    mitigation_conditions JSONB,
    CONSTRAINT chk_jit_timebound CHECK (valid_until > valid_from AND EXTRACT(EPOCH FROM (valid_until - valid_from)) <= 86400)
);
