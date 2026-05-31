import { TransactionClient } from '../database/unit-of-work.impl';
import crypto from 'crypto';

export class OutboxPublisherImpl {
  async publish(tx: TransactionClient, dto: any) {
    const idempotencyKey = crypto
      .createHash('sha256')
      .update(`${dto.contextBundle.tenant_id}-${dto.contextBundle.correlation_id}-${dto.movement_type}`)
      .digest('hex');

    const payloadStr = JSON.stringify({
      warehouse_id: dto.warehouse_id,
      item_id: dto.item_id,
      quantity: dto.quantity,
      movement_type: dto.movement_type
    }).replace(/'/g, "''"); // escape single quotes for SQL

    await tx.$executeRawUnsafe(`
      INSERT INTO outbox_events (tenant_id, correlation_id, idempotency_key, aggregate_type, aggregate_id, event_type, payload, status)
      VALUES (
        '${dto.contextBundle.tenant_id}',
        '${dto.contextBundle.correlation_id}',
        '${idempotencyKey}',
        'WarehouseStock',
        '${dto.warehouse_id}',
        'StockMovementRecorded',
        '${payloadStr}'::jsonb,
        'pending'
      )
    `);
  }
}
