-- ============================================================================
-- ملف: 04_reconciliation_snapshots.sql
-- ============================================================================
-- الغرض المعماري: تخزين نتائج المطابقة المالية بين النطاقات (Reconciliation Snapshots)
-- كتقييم نطاقي مفصول (Domain Evaluation) بدلاً من قيد قاعدة بيانات جامد.
-- الثابت الذي يفرضه: INV-RECONCILIATION-EVAL
-- القيود التقنية: جدول لتسجيل نتائج التقييم لأغراض التدقيق. المنطق الحسابي (Drift Calculation)
-- يقع حصرياً في Domain Services، وتُحذف القيود الثابتة من مستوى قواعد البيانات لمنع الخلط.
-- ============================================================================

CREATE TABLE IF NOT EXISTS reconciliation_snapshots (
    snapshot_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    fiscal_period VARCHAR(20) NOT NULL,
    source_domain VARCHAR(50) NOT NULL,
    target_domain VARCHAR(50) NOT NULL,
    calculated_drift NUMERIC(18,4) NOT NULL,
    reconciliation_status VARCHAR(30) NOT NULL CHECK (reconciliation_status IN ('matched', 'unmatched', 'under_review', 'approved_variance')),
    evaluated_by VARCHAR(100) NOT NULL,
    evaluated_at TIMESTAMP WITH TIME ZONE NOT NULL
);
