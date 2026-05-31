-- ============================================================================
-- 01_policy_evaluation_contract.sql
-- الغرض المعماري: توثيق قرارات الصلاحية وفصل التقييم عن التخزين.
-- الثابت: INV-POLICY-EVAL-PIPELINE, INV-DENY-OVERRIDE-PRIO
-- ============================================================================

CREATE TABLE IF NOT EXISTS role_permissions (
    permission_id UUID PRIMARY KEY,
    role_id UUID NOT NULL,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    policy_effect VARCHAR(20) NOT NULL CHECK (policy_effect IN ('allow', 'deny', 'override')),
    priority INT NOT NULL DEFAULT 100, -- حسم التعارض (1 أعلى)
    source_layer VARCHAR(50) NOT NULL DEFAULT 'RBAC' CHECK (source_layer IN ('RBAC', 'ABAC', 'JIT', 'SYSTEM')),
    evaluation_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS authz_decision_audit (
    decision_id UUID PRIMARY KEY,
    request_id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    user_id UUID NOT NULL,
    target_resource VARCHAR(255) NOT NULL,
    requested_action VARCHAR(100) NOT NULL,
    evaluated_effect VARCHAR(20) NOT NULL CHECK (evaluated_effect IN ('allow', 'deny')),
    evaluation_reason TEXT,
    evaluated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'ArchitecturalViolation: Authorization audit records are immutable.' USING ERRCODE = 'E0001';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_authz_audit_immutable
BEFORE UPDATE OR DELETE ON authz_decision_audit
FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();
