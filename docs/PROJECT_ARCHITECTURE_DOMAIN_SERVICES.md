# Domain Services Architecture

## 1. Core Mandate
This layer encapsulates the core business logic, policies, and workflows. It acts as the only boundary where business rules are evaluated and executed.

## 2. Allowed Responsibilities
- **Business Workflows:** Coordinating multi-step operations within a single isolated domain.
- **Invariant Enforcement:** Halting operations if domain invariants are breached (e.g., negative stock, unmatched accounting entries).
- **Aggregate Root Interaction:** All state changes must pass through a designated Aggregate Root.
- **Unit of Work Management:** Injecting the `UnitOfWork` repository to ensure atomicity.
- **Event Publishing:** Generating Domain Events explicitly configured within documented contracts.

## 3. Strictly Forbidden
- **No Direct Database Access:** Domains cannot use raw SQL outside of the `UnitOfWork` or Repository abstractions.
- **No Cross-Domain Direct Writing:** An Inventory Service cannot directly write an entry to the Journal. It must dispatch an event or call a registered Financial API.
- **No Http/Network Awareness:** Domains do not read Request/Response objects, headers, or parameters. They only consume pure Data Transfer Objects (DTOs).
