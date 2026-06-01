# Database Governance Architecture

## 1. Core Mandate
PostgreSQL is the ultimate Source of Truth. It enforces hard data integrity, relational constraints, and multi-tenant isolation via Row-Level Security (RLS). 

## 2. Allowed Responsibilities
- **Data Integrity:** ACID properties, strictly typed columns.
- **Relational Integrity:** Foreign keys (composite where multi-tenant mapping dictates).
- **Tenant Isolation:** Enforcing `tenant_id` scopes natively using `FORCE ROW LEVEL SECURITY`.
- **Database Triggers for Safety:** Implementing final-line-of-defense checks (e.g., ensuring Double Entry balance, SoD conflict prevention).

## 3. Strictly Forbidden
- **No Implicit Multi-tenancy:** Any query lacking explicit RLS context will default to returning 0 rows.
- **No External API Calls:** PostgreSQL must not query external HTTP endpoints or services.
- **No Soft Deletions on Financials:** Accounting entries (Journals, Ledger) are append-only. No updates to posted records; deletions via explicit Reversal entries only.
- **No Hidden Business Logic:** Stored procedures should not perform dynamic domain decision-making. Their sole purpose is invariant data safety.
