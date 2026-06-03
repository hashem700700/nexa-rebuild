import { PrismaClient } from '@prisma/client';

// Define the transaction context type from Prisma
type PrismaTransaction = Parameters<Parameters<PrismaClient['$transaction']>[0]>[0];

/**
 * Executes a Unit of Work (callback) within a single transaction that has the 
 * tenant context set via RLS policies.
 * 
 * ARCHITECTURAL FIXES:
 * 1. Uses parametrized $executeRaw to prevent SQL Injection (P1).
 * 2. Employs a Unit of Work pattern (UoW) instead of Prisma Extensions, ensuring 
 *    multiple operations share ONE transaction instead of wrapping each query 
 *    in nested transactions (P2).
 */
export async function runWithTenantContext<T>(
  prisma: PrismaClient, 
  tenantId: string, 
  work: (tx: PrismaTransaction) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx: PrismaTransaction) => {
    // Safely set the current tenant context for RLS in this transaction session.
    // Using tagged template literal avoids SQL injection vulnerabilities.
    await tx.$executeRaw`SELECT set_config('app.current_tenant_id', ${tenantId}, true)`;
    
    // Execute all domain/data operations securely within the established tenant context
    return await work(tx);
  });
}
