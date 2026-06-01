# Master Role Visibility & Permission Matrix

## 1. System Roles Definitions
- **SuperAdmin:** Global system owner (system level).
- **TenantAdmin:** Owner/Manager for a specific company branch/tenant.
- **Accountant:** Can manage chart of accounts, view reports, create manual journals.
- **InventoryManager:** Receives stock, adjusts stock, fulfills orders.
- **SalesAgent:** Creates quotes, converts to orders, initiates checkout.

## 2. Segregation of Duties (SoD) Constraints
- `InventoryManager` CANNOT possess `Accountant` role.
- `SalesAgent` CANNOT possess `InventoryManager` role.

## 3. Visibility Matrix (UI/API)
| Feature/Module | SuperAdmin | TenantAdmin | Accountant | InventoryManager | SalesAgent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **System Billing** | VIEW, EDIT | NONE | NONE | NONE | NONE |
| **Tenant Settings** | VIEW | VIEW, EDIT | NONE | NONE | NONE |
| **Chart of Accounts** | VIEW | VIEW | VIEW, EDIT | NONE | NONE |
| **Journal Entries** | VIEW | VIEW | VIEW, ADD | NONE | NONE |
| **Inventory Stock** | VIEW | VIEW | VIEW | VIEW, EDIT | VIEW |
| **Sales Orders** | VIEW | VIEW | VIEW | VIEW | VIEW, ADD |

## 4. API & Projection Hardening
Endpoints and Firestore projections will filter strictly based on role-visibility mappings to prevent inadvertent data leakage.
