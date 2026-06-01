import { getPrisma } from '../../lib/prisma';

const prisma = getPrisma();

async function seed() {
  const TENANT_ID = '00000000-0000-0000-0000-000000000001';
  
  // Create tables manually since this bypasses standard Prisma migrations for this raw test
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS system_tenants (
        tenant_id UUID PRIMARY KEY,
        company_name VARCHAR(255) NOT NULL,
        status VARCHAR(50) NOT NULL
    )
  `);

  await prisma.$executeRawUnsafe(`
    INSERT INTO system_tenants (tenant_id, company_name, status)
    VALUES ('${TENANT_ID}', 'DemoCorp', 'active')
    ON CONFLICT DO NOTHING
  `);

  console.log('[SEED] Tenant created:', TENANT_ID);
}

seed().catch(err => {
  console.error(err);
  process.exit(1);
}).finally(() => prisma.$disconnect());
