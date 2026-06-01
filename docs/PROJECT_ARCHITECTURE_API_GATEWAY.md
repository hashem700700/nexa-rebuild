# API Gateway & BFF (Backend for Frontend) Architecture

## 1. Core Mandate
The API Gateway is the **sole entry point** for all external traffic. It acts strictly as a traffic router, validator, and security enforcement point.

## 2. Allowed Responsibilities
- **Authentication:** Extracting standard JWT tokens or session cookies.
- **Token Validation:** Cryptographic verification of tokens including issuer, structural integrity, and expiration.
- **Authorization Pre-flight:** Calling the `AuthzKernel` to verify if the active role has permissions to execute the requested route.
- **Structural Validation:** Ensuring inbound JSON payloads match defined schemas (e.g., via Zod).
- **Traceability:** Generating and propagating `X-Correlation-Id` across all internal calls.
- **Context Injection:** Setting `tenant_id` and `user_id` inside internal request contexts so domain services receive trusted variables.

## 3. Strictly Forbidden
- **Zero Business Logic:** The Gateway cannot evaluate domain rules (e.g., "if account balance < 0").
- **Zero Database Access:** No raw SQL, no ORM usage (except for querying the RBAC matrix via AuthzKernel).
- **Zero State Mutation:** The Gateway itself does not update or insert any data. It delegates entirely to Domain Services.
- **No Direct Financial Decisions:** Impossible for the Gateway to write to the ledger.
