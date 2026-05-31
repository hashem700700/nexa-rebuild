-- ============================================================================
-- ملف: 02_observability_slo_governance.sql
-- ============================================================================
-- الغرض المعماري: تحويل المراقبة (Observability) من مستوى تجميع بيانات سلبي إلى 
-- حوكمة نشطة عبر ربط كل مقياس أو تنبيهات باشتراطات أداء (SLO) وخطط تشغيل (Runbooks).
-- الثابت الذي يفرضه: INV-OBSERVABILITY-GOVERNANCE
-- القيود التقنية: لا يوجد إشعار/تنبيه مجرد. كل تنبيه يجب أن يُربط بمرجع خطة 
-- واستجابة محددة لمنع عشوائية التشغيل.
-- ============================================================================

CREATE TABLE IF NOT EXISTS slo_governance_registry (
    slo_id UUID PRIMARY KEY,
    domain_service VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL, -- e.g., 'API_Latency', 'DB_Deadlock_Rate', 'Saga_Timeout_Rate'
    threshold_value NUMERIC(15,4) NOT NULL,
    threshold_operator VARCHAR(10) NOT NULL CHECK (threshold_operator IN ('>', '<', '>=', '<=', '==')),
    
    -- الربط الإلزامي بالامتثال
    runbook_reference_url VARCHAR(255) NOT NULL,
    escalation_policy_id UUID NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS observability_alert_events (
    alert_event_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    slo_id UUID NOT NULL REFERENCES slo_governance_registry(slo_id),
    tenant_id UUID, -- NULL if global systemic alert
    
    -- التوثيق
    measured_value NUMERIC(15,4) NOT NULL,
    alert_status VARCHAR(20) NOT NULL CHECK (alert_status IN ('firing', 'acknowledged', 'mitigated', 'resolved')),
    
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Contract Note: Prometheus/Datadog or similar external engines must map their 
-- alerting rules to these SLO registries. Unmapped alerts describe operational noise.
