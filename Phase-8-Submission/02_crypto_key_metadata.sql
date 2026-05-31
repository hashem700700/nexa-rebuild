-- ============================================================================
-- ملف: 02_crypto_key_metadata.sql
-- ============================================================================
-- الغرض المعماري: فصل مفاتيح التشفير السري عن قاعدة البيانات وتخزين مرجعيات 
-- إدارتها ودورانها (KMS metadata) لضمان سرية البيانات الحساسة مثل معلومات PII.
-- الثابت الذي يفرضه: INV-CRYPTO-KEY-SEPARATION
-- القيود التقنية: الـ Database تخزن الـ Ciphertext فقط مع referential identifier
-- للمفتاح في الـ KMS الخارجي. المفتاح الواضح (Plaintext) لا يُخزن إطلاقاً.
-- ============================================================================

CREATE TABLE IF NOT EXISTS crypto_key_metadata (
    key_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    kms_reference_id VARCHAR(255) NOT NULL, -- معرف المفتاح في AWS KMS أو Azure KeyVault
    key_purpose VARCHAR(100) NOT NULL CHECK (key_purpose IN ('pii_encryption', 'audit_signing', 'export_signature')),
    rotation_policy VARCHAR(50) NOT NULL DEFAULT 'annual',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'rotated', 'revoked')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rotated_at TIMESTAMP WITH TIME ZONE
);

-- Contract Note: Encryption/Decryption logic is completely outsourced to Domain Services.
-- DB schemas must treat encrypted payloads as opaque BYTES or base64 TEXT.
