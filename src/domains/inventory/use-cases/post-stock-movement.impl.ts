import { UnitOfWork } from '../../../infrastructure/database/unit-of-work.impl';
import { z } from 'zod';
import { ContractError } from '../../../gateway/error_handler/contract-error';
import { JournalPosterImpl } from '../../accounting_core/services/journal-poster.impl';
import { OutboxPublisherImpl } from '../../../infrastructure/event_bus/outbox-publisher.impl';

const stockMovementSchema = z.object({
  warehouse_id: z.string().uuid(),
  item_id: z.string().uuid(),
  quantity: z.number().refine(q => q !== 0, 'Quantity must be non-zero'),
  movement_type: z.enum(['receipt', 'issue', 'adjustment']),
  reference_document: z.string().optional(),
  contextBundle: z.any()
});

export class PostStockMovementUseCase {
  constructor(private readonly uow: UnitOfWork) {}

  async execute(dto: any) {
    const validated = stockMovementSchema.safeParse(dto);
    if (!validated.success) throw new ContractError('VALIDATION_FAILED', validated.error.flatten());

    return this.uow.execute(dto.contextBundle.tenant_id, async (tx) => {
      // 1. Insert Stock Movement
      await tx.$executeRawUnsafe(`
        INSERT INTO stock_movements (tenant_id, warehouse_id, item_id, quantity, movement_type, reference_document, correlation_id, status)
        VALUES (
          '${dto.contextBundle.tenant_id}',
          '${dto.warehouse_id}',
          '${dto.item_id}',
          ${dto.quantity},
          '${dto.movement_type}',
          ${dto.reference_document ? `'${dto.reference_document}'` : 'NULL'},
          '${dto.contextBundle.correlation_id}',
          'completed'
        )
      `);

      // 2. Accounting Kernel
      const journalPoster = new JournalPosterImpl();
      await journalPoster.post(tx, dto);

      // 3. Outbox Publisher
      const outboxPublisher = new OutboxPublisherImpl();
      await outboxPublisher.publish(tx, dto);

      return { status: 'committed', correlation_id: dto.contextBundle.correlation_id };
    });
  }
}
