-- ============================================================================
-- ملف: 03_dr_compliance_governance.sql
-- ============================================================================
-- الغرض المعماري: حوكمة سياسات الاسترداد من الكوارث (DR) وتسجيل محاولات 
-- الاسترداد التجريبية والامتثال للمتطلبات التنظيمية العابرة للنطاقات.
-- الثابت الذي يفرضه: INV-DR-GOVERNANCE, INV-CROSS-TENANT-COMPLIANCE
-- القيود التقنية: تتبع دقيق لأهداف نقطة الاسترداد (RPO) ووقت الاسترداد (RTO).
-- توثيق موقع الإقامة البياناتي (Data Residency) لكل مستأجر وتدقيق الامتثال.
-- ============================================================================

CREATE TABLE IF NOT EXISTS tenant_compliance_profiles (
    profile_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL UNIQUE,
    data_residency_region VARCHAR(50) NOT NULL, -- e.g., 'eu-west-1', 'me-south-1'
    required_rpo_minutes INT NOT NULL DEFAULT 60,
    required_rto_minutes INT NOT NULL DEFAULT 240,
    regulatory_framework VARCHAR(100) NOT NULL, -- e.g., 'SOX+GDPR+LocalTax'
    retention_override_policy JSONB,
    export_signing_authority VARCHAR(50) NOT NULL DEFAULT 'system_integrity'
);

CREATE TABLE IF NOT EXISTS disaster_recovery_drill_logs (
    drill_id UUID PRIMARY KEY,
    drill_type VARCHAR(50) NOT NULL CHECK (drill_type IN ('simulated', 'actual_failover')),
    target_region VARCHAR(50) NOT NULL,
    achieved_rpo_minutes INT,
    achieved_rto_minutes INT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failed', 'partial')),
    evaluated_by UUID NOT NULL,    
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Contract Note: Backup operations must emit events to prove RPO adherence externally.
-- Tenant compliance profile forces infrastructure routing (e.g., routing EU tenant DB strictly to EU shard).
