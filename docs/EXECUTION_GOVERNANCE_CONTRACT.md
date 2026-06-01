# Execution Governance Contract (EGC)

This document formalizes the architectural boundaries, responsibilities, and immutable constraints for the core system layers. Any implementation that violates these invariants is considered architecturally invalid.

## 1. API Gateway / BFF (Backend for Frontend) Layer
**Primary Role:** The sole entry point for all external traffic and the frontend. It operates strictly as a traffic router, validator, and security guard.

### ✅ Allowed (Mandatory Responsibilities)
- **Authentication & Parsing:** Extracting JWTs, resolving headers.
- **Token Validation:** Verifying token signature, issuer, and expiration.
- **Authorization Delegation:** Passing the request to the `AuthzKernel` to verify permissions (Checking only, **not** deciding logic).
- **Rate Limiting & Throttling:** Guarding the system from DDoS or abuse.
- **Request Validation:** Structural schema validation (e.g., Zod) ensuring input format is correct.
- **Traceability:** Injecting and propagating `X-Correlation-Id` and `X-Tenant-Id` to all downstream requests.

### ❌ Forbidden
- **No Business Logic:** Cannot make decisions based on the content of the data (e.g., "if amount > 1000 deny").
- **No Financial Decisions:** Cannot originate accounting entries or evaluate financial state.
- **No Direct Data Manipulation:** Cannot write or update data in the database directly.
- **No Domain Bypassing:** Must route all valid actions through the respective Domain Service Use Cases.

---

## 2. PostgreSQL Database Layer (Source of Truth)
**Primary Role:** The definitive, immutable storage of all core system and financial data. Responsible for enforcing absolute data integrity and multi-tenant isolation at the lowest physical level.

### ✅ Allowed (Mandatory Responsibilities)
- **Final State Reads/Writes:** Storing the committed output of the domain services.
- **Relational Constraints:** Enforcing Foreign Keys, Unique constraints, and Null checks.
- **Indexes:** Optimizing query performance without altering behavior.
- **Tenant Isolation (RLS):** Using Row Level Security (RLS) to enforce strict boundaries using `tenant_id`, `company_id`, and `branch_id`. Any query missing the `tenant_id` context MUST return `∅` (0 rows).
- **Core Data Integrity:** Ensuring Atomicity, Consistency, Isolation, and Durability (ACID).

### ❌ Forbidden
- **No Business Rules:** Cannot contain logic like "calculate final tax amount" within Triggers.
- **No Calculations:** No complex financial logic or conditional workflows built natively into stored procedures.
- **No External Calls:** Database cannot make HTTP calls to third-party APIs.
- **No Soft Isolation:** Cannot rely on the application code to append `WHERE tenant_id = x`; isolation must be enforced inherently by RLS policies.

---

## 3. Domain Services Layer
**Primary Role:** The heart of the business logic. Encapsulates and implements all business rules, workflows, policies, and domain invariants.

### ✅ Allowed (Mandatory Responsibilities)
- **Business Rules:** Implementing core domain policies (e.g., "cannot sell inventory that is not in stock").
- **Workflows:** Coordinating complex operations within a specific, isolated Bounded Context.
- **Domain Validation Rules:** Enforcing domain-specific rules on incoming data objects prior to execution.
- **Aggregate Root Ownership:** Ensuring all changes to an aggregate are made through its root entity.
- **Transaction Boundaries:** Scoping operations within a `Unit of Work` to ensure atomicity.
- **Documented Event Contracts:** Publishing domain events (via Transactional Outbox) strictly based on formalized contracts.

### ❌ Forbidden
- **No Direct Database Access:** Must rely exclusively on the Repository Abstraction (`Unit of Work`). Cannot write raw SQL directly in services.
- **No Cross-Domain State Sharing:** Cannot mutate or directly read state that belongs to another Domain.
- **No Undocumented Side-Effects:** Any output outside the domain must be handled via published events, not hidden API calls.
