-- ============================================================================
-- 01_gateway_security_contract.sql
-- الغرض المعماري: فصل التتبع (Correlation) عن الهوية الأساسية للطلب (Request)
-- الثوابت: INV-REQUEST-UNIQUE
-- ============================================================================

CREATE TABLE IF NOT EXISTS gateway_request_audit (
    request_id UUID PRIMARY KEY, -- PK هو هوية الحدث الطلبي الحقيقية
    correlation_id UUID NOT NULL, -- للبحث والتتبع
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL, 
    endpoint_path VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INT NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for effective audit tracing without causing duplicate PK issues
CREATE INDEX idx_gateway_audit_correlation ON gateway_request_audit(correlation_id);
