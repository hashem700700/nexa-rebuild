import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function runTests() {
  const TENANT_ID = '00000000-0000-0000-0000-000000000001';
  const CORR_ID = '550e8400-e29b-41d4-a716-446655440000';

  console.log('--- STARTING CONSTITUTIONAL VALIDATION MATRIX ---');

  // 1. Check Atomicity
  const moveCount = await prisma.$queryRawUnsafe<{count: bigint}[]>(`SELECT count(*) FROM stock_movements WHERE correlation_id = '${CORR_ID}'`);
  console.log('[INV-SLICE-ATOMICITY] stock_movements count:', Number(moveCount[0].count));

  const journalCount = await prisma.$queryRawUnsafe<{count: bigint}[]>(`SELECT count(*) FROM journal_entries WHERE correlation_id = '${CORR_ID}'`);
  console.log('[INV-SLICE-ATOMICITY] journal_entries count:', Number(journalCount[0].count));

  // 2. Check DB Imbalance
  const totals = await prisma.$queryRawUnsafe<{total_debit: number, total_credit: number}[]>(`
    SELECT SUM(debit_amount) as total_debit, SUM(credit_amount) as total_credit 
    FROM journal_lines WHERE journal_id IN (SELECT journal_id FROM journal_entries WHERE correlation_id = '${CORR_ID}')
  `);
  console.log('[INV-DB-ENTRY] Totals:', totals[0]);

  // 3. Outbox
  const outbox = await prisma.$queryRawUnsafe<{status: string, idempotency_key: string}[]>(`
    SELECT status, idempotency_key FROM outbox_events WHERE correlation_id = '${CORR_ID}'
  `);
  console.log('[INV-OUTBOX-IDEMPOTENCY] Outbox state:', outbox[0]);

  // 4. Tenant Isolation
  const tenantCheck = await prisma.$queryRawUnsafe<{tenant_id: string}[]>(`
    SELECT tenant_id FROM stock_movements WHERE correlation_id = '${CORR_ID}'
  `);
  console.log('[INV-TENANT-ISOLATION] Tenant ID match:', tenantCheck[0]?.tenant_id === TENANT_ID);

  console.log('--- DONE ---');
}

runTests().catch(e => console.error(e)).finally(() => prisma.$disconnect());
