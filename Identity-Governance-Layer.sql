-- ============================================================================
-- identity_kernel_registry.sql
-- المرجع المعماري لإدارة الهوية في النظام الموزع (Identity Classification)
-- لا يُسمح بتعديله إلا بواسطة مهندس المعمارية
-- ============================================================================

-- تم توثيق قواعد IGL في هذا العقد ليكون أساسا يرجع إليه أي Code Review.
-- UUID v7: Mandatory for journal_entry, stock_movement, outbox_event
-- UUID v4: Permitted for deterministic projections and read models
-- Correlation ID: Propagated, not regenerated.
