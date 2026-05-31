CREATE TABLE system_tenants (
    tenant_id UUID PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE stock_movements (
    movement_id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL,
    warehouse_id VARCHAR(255) NOT NULL,
    item_id VARCHAR(255) NOT NULL,
    quantity NUMERIC NOT NULL,
    movement_type VARCHAR(50) NOT NULL,
    reference_document VARCHAR(255),
    correlation_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE journal_entries (
    journal_id VARCHAR(255) PRIMARY KEY,
    tenant_id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    journal_date DATE NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE journal_lines (
    line_id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL,
    journal_id VARCHAR(255) NOT NULL,
    account_id VARCHAR(255) NOT NULL,
    debit_amount NUMERIC NOT NULL,
    credit_amount NUMERIC NOT NULL,
    transaction_currency VARCHAR(10) NOT NULL,
    exchange_rate NUMERIC NOT NULL,
    base_debit_amount NUMERIC NOT NULL,
    base_credit_amount NUMERIC NOT NULL
);

CREATE TABLE outbox_events (
    event_id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    idempotency_key VARCHAR(255) UNIQUE NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE projection_inventory_stock (
    tenant_id UUID NOT NULL,
    warehouse_id VARCHAR(255) NOT NULL,
    item_id VARCHAR(255) NOT NULL,
    quantity_on_hand NUMERIC NOT NULL,
    UNIQUE(tenant_id, warehouse_id, item_id)
);
