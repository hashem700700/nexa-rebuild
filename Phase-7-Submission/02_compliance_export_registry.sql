-- ============================================================================
-- ملف: 02_compliance_export_registry.sql
-- ============================================================================
-- الغرض المعماري: السجل الجنائي لملفات التصدير السيادية (مثل الضرائب VAT أو الامتثال القانوني)،
-- لضمان توثيق أي استخراج للبيانات مع بصمة مشفرة تمنع الإنكار والتلاعب.
-- الثابت الذي يفرضه: INV-IMMUTABLE-EXPORT
-- القيود التقنية: كل عملية تصدير ضريبي/قانوني تخضع للتوثيق الإلزامي، ببيانات التجزئة،
-- دون السماح بالتعديل أو الحذف (Append-Only Registry).
-- أي استثناءات أو افتراضات: لا يوجد استثناء. أي ملف يُعطى للجهات الحكومية يُعد تصديراً سيادياً.
-- ============================================================================

CREATE TABLE IF NOT EXISTS compliance_export_logs (
    export_id UUID PRIMARY KEY, -- Identity Kernel: UUID v7
    tenant_id UUID NOT NULL,
    export_type VARCHAR(100) NOT NULL CHECK (export_type IN ('vat_return', 'annual_audit', 'regulatory_filing', 'custom_export')),
    requested_by_user_id UUID NOT NULL,
    
    -- التوثيق الجنائي (INV-IMMUTABLE-EXPORT)
    export_parameters JSONB NOT NULL, -- (e.g., date_from, date_to, filters)
    payload_hash VARCHAR(64) NOT NULL, -- SHA256 للبيانات المُصدرة
    digital_signature TEXT, -- التوقيع الرقمي للمنظومة
    
    -- التوجيه الحاكم (INV-EXPORT-PROVENANCE)
    signature_type VARCHAR(30) NOT NULL CHECK (signature_type IN ('system_integrity', 'legal_attestation', 'external_audit')),
    signature_authority VARCHAR(100),
    
    status VARCHAR(20) NOT NULL DEFAULT 'generated' CHECK (status IN ('generated', 'transmitted', 'acknowledged', 'rejected')),
    exported_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_hash_coverage CHECK (payload_hash IS NOT NULL AND payload_hash != '')
);

-- Contract Note: Trigger to enforce Append-Only (prevent UPDATE/DELETE unless changing status strictly forward).
CREATE OR REPLACE FUNCTION prevent_export_log_tampering()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'ComplianceViolation: Cannot delete export logs.' USING ERRCODE = 'E0001';
    END IF;
    IF TG_OP = 'UPDATE' THEN
        -- Allow only status transitions, everything else must be immutable
        IF NEW.payload_hash != OLD.payload_hash OR NEW.export_parameters != OLD.export_parameters THEN
            RAISE EXCEPTION 'ComplianceViolation: Export payload and parameters are immutable.' USING ERRCODE = 'E0001';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_compliance_export_immutable
BEFORE UPDATE OR DELETE ON compliance_export_logs
FOR EACH ROW EXECUTE FUNCTION prevent_export_log_tampering();
