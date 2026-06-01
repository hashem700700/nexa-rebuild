# Aggregate Ownership Map

## 1. Description
This document defines boundaries and ensures loose coupling. No Domain Service may modify an Aggregate Root belonging to another Domain.

## 2. Aggregates & Owners
### Core Accounting Domain
- **Chart of Accounts:** Owns Accounts, Balances, Account Types.
- **Ledger/Journal:** Owns Journal Entries, Journal Lines, Postings, Reversals.

### Inventory Domain
- **Product Catalog:** Owns Items, SKUs, Variations.
- **Stock Ledger (Movements):** Owns Stock Quantities, Bin Locations, Receiving, Deductibles.

### Sales Domain
- **Sales Order:** Owns Order details, Line Items, Pricing overrides.
- **Customer Directory:** Owns Profiles, Terms, Shipping Addresses.

## 3. Communication Standard
If a `Sales Order` is completed, it CANNOT write a deduction command straight into the `Stock Ledger`. It MUST emit a `SalesOrderFulfilled` Event. The Inventory Domain listens, processes, and safely deducts stock within its own isolated Aggregate scope.
