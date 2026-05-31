-- ============================================================================
-- ملف: 01_legal_hold_registry.sql
-- ============================================================================
-- الغرض المعماري: إدارة التعليق القانوني (Legal Hold) لمنع دورات حياة البيانات
-- (الأرشفة/الحذف) استجابة للتحقيقات أو التدقيقات، فوق أي سياسة أخرى.
-- الثابت الذي يفرضه: INV-LEGAL-HOLD-ENFORCE, INV-LEGAL-HOLD-OVERRIDE
-- القيود التقنية: يُلغي عملياً أي سياسة Retention على السجلات المربوطة. 
-- الأرشفة / الحذف يجب أن تتأكد من جدول hold_active قبل أي تعديل.
-- ============================================================================

CREATE TABLE IF NOT EXISTS legal_hold_cases (
    case_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    case_reference VARCHAR(255) NOT NULL,
    hold_reason TEXT NOT NULL,
    hold_active BOOLEAN NOT NULL DEFAULT true,
    issued_by UUID NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS legal_hold_registries (
    registry_id UUID PRIMARY KEY,
    case_id UUID NOT NULL REFERENCES legal_hold_cases(case_id),
    target_entity VARCHAR(100) NOT NULL, -- e.g., 'journal_entries'
    target_record_id UUID, -- NULL implies entire entity type for tenant is under hold
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Contract Note: Any Purge/Archive action must strictly evaluate:
-- SELECT hold_active FROM legal_hold_cases JOIN legal_hold_registries WHERE ...
-- If True -> Throw ArchitecturalViolation (Code A008) "Legal Hold Active"
