-- ============================================================================
-- ملف: 01_reporting_projection_contracts.sql
-- ============================================================================
-- الغرض المعماري: تعريف نماذج القراءة الخاصة بالتقارير (Reporting Projections) لفصل 
-- مسار التحليلات والقراءة الثقيلة عن مسار الكتابة التشغيلي كلياً (CQRS Reporting Isolation).
-- الثابت الذي يفرضه: INV-REPORT-ISOLATION
-- القيود التقنية: 
--  1. يمنع منعاً باتاً استعلام القواعد التشغيلية (Write-Path) مباشرة لغرض التقارير.
--  2. التقارير تُبنى حصرياً من Projection Tables أو Materialized Views.
-- أي استثناءات أو افتراضات: اللحظية التامة (Perfect Real-time) غير مضمونة في التقارير 
-- بسبب طبيعة التحديث غير المتزامن لطبقة الـ Projection.
-- ============================================================================

-- جدول يمثل Projection مخصص لغرض تقرير معين (مثال: ميزان المراجعة اليومي)
CREATE TABLE IF NOT EXISTS report_projection_trial_balance (
    tenant_id UUID NOT NULL,
    fiscal_period VARCHAR(20) NOT NULL,
    account_id UUID NOT NULL,
    account_code VARCHAR(50) NOT NULL,
    starting_balance NUMERIC(18,4) NOT NULL DEFAULT 0,
    period_debit NUMERIC(18,4) NOT NULL DEFAULT 0,
    period_credit NUMERIC(18,4) NOT NULL DEFAULT 0,
    ending_balance NUMERIC(18,4) GENERATED ALWAYS AS (starting_balance + period_debit - period_credit) STORED,
    last_applied_event_id UUID NOT NULL, -- للتحقق من مستوى تقدم التحديث 
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, fiscal_period, account_id)
);
-- Contract Note: This table is ONLY updated by the Projection Relayer, NEVER by direct user input.
-- INV-PROJECTION-NO-FEEDBACK: Reporting Engine consumes only from Read-Models. 
-- Any feedback loop to Write-Path triggers Architectural Violation (Code A007).
-- RLS Enforcement: Must be subjected to standard Row Level Security for tenant isolation.

-- عرض محصن (Materialized View) للتقارير الثقيلة (e.g. Sales Aggregation)
-- ملاحظة معمارية: تحديث هذا العرض يتم عبر Cron Job مجدول أو Event Trigger بعيداً عن الـ Hot-Path
CREATE MATERIALIZED VIEW IF NOT EXISTS mvw_monthly_inventory_valuation AS
SELECT 
    tenant_id,
    warehouse_id,
    item_id,
    EXTRACT(YEAR FROM "updated_at") AS valuation_year,
    EXTRACT(MONTH FROM "updated_at") AS valuation_month,
    AVG(calculated_quantity) AS average_stock_on_hand
FROM projection_inventory_stock
GROUP BY tenant_id, warehouse_id, item_id, valuation_year, valuation_month;

CREATE UNIQUE INDEX idx_mvw_monthly_inventory ON mvw_monthly_inventory_valuation (tenant_id, warehouse_id, item_id, valuation_year, valuation_month);
