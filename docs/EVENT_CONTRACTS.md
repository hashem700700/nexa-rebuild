# Event Contracts & Schemas

## 1. Description
Domain Events communicate state changes across completely isolated bounded contexts. An Event represents something strictly historical ("This happened").

## 2. Standard Schema
All events MUST adhere to the following Outbox Event Schema:

| Field | Type | Description |
| :--- | :--- | :--- |
| `event_id` | UUID | Unique identifier, ensures idempotency |
| `tenant_id` | String | Context Isolation |
| `aggregate_type` | String | e.g. "Inventory" |
| `aggregate_id` | String | Specific Record ID |
| `event_type` | String | e.g. "StockDeducted", "OrderFulfilled" |
| `payload` | JSONB | Highly specific structural data payload (Versioned) |
| `correlation_id` | UUID | Traces an operation seamlessly across distributed systems |

## 3. Strict Rules
- Events MUST be backwards and forwards compatible.
- Consumers MUST be Idempotent (processing the identical `event_id` twice must safely ignore the duplicate).
- Payloads MUST NOT transmit entire table snapshots; transfer ONLY identifiers and necessary diff parameters or explicitly required lookup values.
