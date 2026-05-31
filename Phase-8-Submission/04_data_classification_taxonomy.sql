-- ============================================================================
-- ملف: 04_data_classification_taxonomy.sql
-- ============================================================================
-- الغرض المعماري: تعريف تسلسل هرمي موحد لتصنيف البيانات (Data Taxonomy) يحكم جميع 
-- السياسات الأخرى (التشفير، الاحتفاظ، والوصول).
-- الثابت الذي يفرضه: INV-DATA-CLASSIFICATION
-- القيود التقنية: جميع جداول النظام التي تخزن بيانات يجب أن تعلن عن classification_id
-- يرث السياسات من هذا الجدول.
-- ============================================================================

CREATE TABLE IF NOT EXISTS data_classification_taxonomy (
    class_id UUID PRIMARY KEY,
    class_label VARCHAR(30) NOT NULL UNIQUE CHECK (class_label IN ('PUBLIC','INTERNAL','CONFIDENTIAL','RESTRICTED','PERMANENT_IMMUTABLE')),
    retention_tier VARCHAR(50) NOT NULL,
    encryption_tier VARCHAR(50) NOT NULL,
    audit_mandatory BOOLEAN NOT NULL DEFAULT TRUE
);

-- Contract Note: All operational tables MUST declare a classification_id logically.
-- Archiving, Retentions, and Purge engines apply policies inherited from this generic taxonomy.
