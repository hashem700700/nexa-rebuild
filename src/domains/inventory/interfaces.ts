export interface StockMovement {
    movement_id: string; // UUID v7
    tenant_id: string;
    item_id: string;
    warehouse_id: string;
    quantity: number; // positive for expected addition, negative for deduction
    movement_type: 'ISSUE' | 'RECEIPT' | 'TRANSFER';
    correlation_id: string;
    status: 'PENDING' | 'COMPLETED' | 'FAILED';
}

export interface InventoryService {
    createMovement(movement: StockMovement): Promise<void>;
}
