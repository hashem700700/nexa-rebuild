# NEXA ERP - Technical Debt Registry

* TODO-[DEBT]: `journal_lines.line_id` is using `autoincrement()` instead of UUIDv7 | owner: Core Team | phase: Wave 1 Refactoring
* TODO-[DEBT]: `stock_movements.movement_id` is using `autoincrement()` instead of UUIDv7 | owner: Core Team | phase: Wave 1 Refactoring
* TODO-[DEBT]: `outbox_events.event_id` is using `autoincrement()` instead of UUIDv7 | owner: Core Team | phase: Wave 1 Refactoring
* TODO-[DEBT]: `journal_entries.journal_id` is using `VarChar(255)` instead of UUIDv7 | owner: Core Team | phase: Wave 1 Refactoring
* TODO-[DEBT]: Files located in `Phase-6-Submission/*.sql` are outside the `migrations/` directory violating Rule 24 | owner: Core Team | phase: Pipeline Cleanup
* TODO-[DEBT]: `Phase-2-Submission/02_atomic_posting_wrapper.sql` was deleted due to UUIDv4 `gen_random_uuid()` usage and schema mismatch (Active Compliance Violation) | owner: Core Team | phase: Wave 1 Refactoring
