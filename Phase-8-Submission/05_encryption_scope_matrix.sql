-- ============================================================================
-- ملف: 05_encryption_scope_matrix.sql
-- ============================================================================
-- الغرض المعماري: مصفوفة نطاق التشفير (Encryption Scope) لتحديد الحقول 
-- الخاضعة للتشفير الإلزامي أو الممنوعة من التشفير بناءً على التصنيف.
-- الثابت الذي يفرضه: INV-ENCRYPTION-SCOPE-MATRIX
-- القيود التقنية: يمنع منعاً باتاً تخزين أي مواد تشفيرية (plaintext keys) 
-- في مستوى الـ Schema. يتم تخزين الـ kms_ref و ciphertext فقط.
-- ============================================================================

CREATE TABLE IF NOT EXISTS column_encryption_scope (
    scope_id UUID PRIMARY KEY,
    entity_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    classification_ref UUID NOT NULL REFERENCES data_classification_taxonomy(class_id),
    encryption_scope VARCHAR(20) NOT NULL CHECK (encryption_scope IN ('MANDATORY','OPTIONAL','FORBIDDEN')),
    kms_key_ref_pattern VARCHAR(255) NOT NULL,
    CONSTRAINT uq_entity_column_scope UNIQUE (entity_name, column_name)
);

-- Contract Note: KMS handles key lifecycle. DB stores ONLY ciphertext + kms_ref. 
-- No plaintext key material allowed anywhere in the database schema.
