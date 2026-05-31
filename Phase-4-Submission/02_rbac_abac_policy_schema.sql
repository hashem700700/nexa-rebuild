-- ============================================================================
-- 02_rbac_abac_policy_schema.sql
-- الغرض المعماري: تخزين تعريفات الهيكل الوظيفي للأدوار. التقسيم التنفيذي
-- للسياسات تم نقله إلى Application Layer في (Phase 5).
-- ============================================================================

CREATE TABLE IF NOT EXISTS system_roles (
    role_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    is_operational BOOLEAN NOT NULL DEFAULT false,
    is_financial BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT chk_privilege_bound CHECK (NOT (is_operational AND is_financial))
);
