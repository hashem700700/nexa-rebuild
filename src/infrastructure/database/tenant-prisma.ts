import { PrismaClient } from '@prisma/client';

/**
 * Creates a Prisma Client extension that automatically binds the tenant context
 * to the PostgreSQL session via set_config for ALL queries within a transaction
 * explicitly to prevent connection pool multiplexing races.
 * 
 * We enforce this at the Client Extension level so that developers cannot 
 * accidentally query data outside of RLS bypass protection.
 */
export function createTenantPrisma(prisma: PrismaClient, tenantId: string) {
  return prisma.$extends({
    query: {
      $allModels: {
        async $allOperations({ args, query }) {
          // By wrapping the operation in an interactive transaction with the set_config,
          // we guarantee that the connection leased from the pool will have the correct tenant context.
          // Because isolation level is maintained for the lifecycle of the transaction, no other
          // async queries will pollute this specific connection.
          const [, result] = await prisma.$transaction([
            prisma.$executeRawUnsafe(`SELECT set_config('app.current_tenant_id', '${tenantId}', true)`),
            // The actual domain query
            query(args)
          ]);
          return result;
        }
      }
    }
  });
}
