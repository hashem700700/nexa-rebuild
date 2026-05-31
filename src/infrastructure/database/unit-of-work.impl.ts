import { PrismaClient } from '@prisma/client';

export type TransactionClient = Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;

export class UnitOfWork {
  constructor(private readonly prisma: PrismaClient) {}

  async execute<T>(
    tenantId: string,
    handler: (tx: TransactionClient) => Promise<T>
  ): Promise<T> {
    return this.prisma.$transaction(async (tx) => {
      // =========================
      // INV: TENANT CONTEXT BINDING
      // =========================
      await tx.$executeRawUnsafe(
        `SELECT set_config('app.current_tenant_id', '${tenantId}', true)`
      );

      // =========================
      // CRITICAL RULE:
      // all operations MUST use this tx only
      // =========================
      try {
        const result = await handler(tx);
        return result;
      } catch (err) {
        // rollback is automatic in Prisma transaction
        throw err;
      }
    }, {
      isolationLevel: 'Serializable', // INV-DB-ENTRY STRONGEST GUARANTEE
      maxWait: 5000,
      timeout: 30000
    });
  }
}
