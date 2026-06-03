import { PrismaClient } from '@prisma/client';
import { runWithTenantContext, PrismaTransaction } from './tenant-prisma';

export type TransactionClient = Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;

export class UnitOfWork {
  constructor(private readonly prisma: PrismaClient) {}

  async execute<T>(
    tenantId: string,
    handler: (tx: TransactionClient) => Promise<T>
  ): Promise<T> {
    // =========================
    // INV: TENANT CONTEXT BINDING
    // =========================
    // Delegating to the unified runner
    return runWithTenantContext(this.prisma, tenantId, handler as any);
  }
}
