# Transaction Boundaries & Scopes

## 1. Unit of Work (UoW) Pattern Scope
A `UnitOfWork` guarantees atomicity across independent repository calls.
- **Rule:** A database transaction MUST be opened explicitly by the Domain Service entry point.
- **Rule:** A transaction CANNOT span across multiple bounded contexts (e.g., updating Inventory records and persisting Journal Entries must be separate transactions bridged by the Outbox pattern).

## 2. Distributed Transactions (Saga Pattern)
When an operation requires changes in multiple domains (e.g., Completing a Sale triggers Stock Deduction and Accounting Posting):
- No 2-Phase Commits (2PC).
- We utilize Event-Choreography or Orchestration resulting in local UoW commits plus transactional outbox payloads.

## 3. Compensation Models
If Step 2 in a transaction chain fails (e.g., Accounting posting fails after Inventory was deducted), a compensation mechanism MUST reverse Step 1 based strictly on the emitted Failure Event. Compensation logic is localized within the triggering aggregate.
