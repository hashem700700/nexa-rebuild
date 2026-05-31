-- ============================================================================
-- ملف: 03_secrets_risk_control_matrix.sql
-- ============================================================================
-- الغرض المعماري: عزل أسرار النظام (Secrets) زمنياً ووظيفياً عن التخزين المباشر.
-- إدارة المخاطر وتصعيد الحالات التشغيلية الحرجة كإطار حوكمة.
-- الثابت الذي يفرضه: INV-SECRETS-VAULT-ISO, INV-RISK-CONTROL-BOUNDARY
-- القيود التقنية: الـ Database لا تخزن Secret values (مثل JWT keys, API keys).
-- تخزن الـ DB فقط تعريف الإعارة (Lease) وتصعيد المخاطر عند الاستخدام الخاطئ.
-- ============================================================================

CREATE TABLE IF NOT EXISTS secret_vault_leases (
    lease_id UUID PRIMARY KEY,
    vault_reference_path VARCHAR(255) NOT NULL, -- e.g., 'hashicorp:vault:secret/api_keys'
    service_identity VARCHAR(100) NOT NULL,
    
    -- حوكمة الزمن (INV-SECRETS-VAULT-ISO)
    lease_duration_seconds INT NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE GENERATED ALWAYS AS (issued_at + (lease_duration_seconds * interval '1 second')) STORED,
    
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked'))
);

CREATE TABLE IF NOT EXISTS operational_risk_escalations (
    escalation_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    risk_category VARCHAR(50) NOT NULL CHECK (risk_category IN ('AuthZ_Storm', 'DB_Deadlock_Spike', 'Secret_Lease_Breach', 'Lag_Spike')),
    detected_source VARCHAR(100) NOT NULL,
    
    -- التعاطي الحتمي مع الخطر (INV-RISK-CONTROL-BOUNDARY)
    auto_mitigation_applied VARCHAR(100), -- e.g., 'CircuitBreakerTrigged', 'LeaseRevoked'
    requires_human_override BOOLEAN NOT NULL DEFAULT false,
    
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'mitigated', 'escalated', 'closed')),
    
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- Contract Note: Risk engine triggers autonomous mitigation (e.g., revoking a lease if compromised).
-- If mitigation fails, it forces human escalation. The DB is an immutable ledger of these risks.
