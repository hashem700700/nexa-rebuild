import { IdempotencyStore } from '../../../infrastructure/cache/interfaces';
import { ProjectionStore } from '../interfaces';
import { PoolClient } from 'pg';

export class StockMovedProjectionHandlerImpl {
  constructor(
    private readonly client: PoolClient,
    private readonly idempotency: IdempotencyStore
  ) {}

  async handle(event: any) {
    const key = `${event.tenant_id}:${event.event_id}`;
    
    // 1. فحص التكرار (INV-OUTBOX-IDEMPOTENCY)
    const exists = await this.idempotency.exists(key);
    if (exists) return { status: 'skipped_duplicate' };

    // 2. تحديث Read-Model (INV-READ-ONLY-DOMAIN)
    const payload = JSON.parse(event.payload);
    const quantityChange = payload.movement_type === 'receipt' ? payload.quantity : -payload.quantity;

    await this.client.query(
      `INSERT INTO projection_inventory_stock (tenant_id, warehouse_id, item_id, quantity_on_hand)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (tenant_id, warehouse_id, item_id)
       DO UPDATE SET quantity_on_hand = projection_inventory_stock.quantity_on_hand + EXCLUDED.quantity_on_hand`,
      [event.tenant_id, payload.warehouse_id, payload.item_id, quantityChange]
    );

    // 3. تسجيل idempotency_key
    await this.idempotency.save(key);

    return { status: 'synchronized' };
  }
}
