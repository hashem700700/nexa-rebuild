# Authorization (AuthZ) & Segregation of Duties (SoD)

## 1. Core Mandate
Authorization evaluates whether an authenticated user is permitted to perform a requested action based on strict RBAC (Role-Based Access Control) and SoD (Segregation of Duties) constraints.

## 2. The 3-Layer SoD Architecture
To prevent fraud and enforce compliance, a user cannot act as both the initiator and approver/performer of conflicting actions (e.g., creating a purchase order and fulfilling it). This is enforced across 3 absolute layers:

### Layer 1: Presentation (UI)
- The frontend client inherently hides, disables, or prevents selection of actions that would violate SoD.

### Layer 2: AuthZ Kernel
- The API Gateway delegates to `AuthzKernel` before handling the request. 
- `AuthzKernel` analyzes the requested action against the user's current roles and active session, blocking the transaction early if an SoD conflict is detected.

### Layer 3: Database (Final Safety Net)
- A trigger on `auth_user_roles` strictly refuses the insertion of inherently conflicting roles (e.g., `creator` + `approver`) for the same entity context.

## 3. Auditing
- Every positive and negative AuthZ decision is hashed and immutably written to an `auth_audit_log`.
