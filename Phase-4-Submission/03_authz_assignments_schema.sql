-- ============================================================================
-- 03_authz_assignments_schema.sql
-- الغرض المعماري: هيكل إسناد الأدوار للمستخدمين ليكون مخزناً (Storage-Only).
-- وتم اسقاط تعقيد SoD من هذه المرحلة ونقله كسياسة في Policy Engine.
-- الثوابت: INV-SOD-EVAL-SEPARATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_role_assignments (
    assignment_id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    role_id UUID NOT NULL REFERENCES system_roles(role_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_role UNIQUE (user_id, role_id)
);
