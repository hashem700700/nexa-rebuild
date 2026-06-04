import { UnitOfWork } from '../src/infrastructure/database/unit-of-work.impl';
import { getPrisma } from '../src/lib/prisma';
import { PostStockMovementUseCase } from '../src/domains/inventory/use-cases/post-stock-movement.impl';
import { randomUUID } from 'crypto';
import { AuthzKernel } from '../src/gateway/middleware/authz-kernel.impl';

async function setupTestData(tenantId: string) {
  const prisma = getPrisma();
  // Ensure tenant exists
  await prisma.system_tenants.upsert({
    where: { tenant_id: tenantId },
    create: { tenant_id: tenantId, company_name: 'Test Tenant', status: 'active' },
    update: {}
  });

  // Setup Role
  const roleId = 'inventory-manager-role';
  await prisma.auth_roles.upsert({
    where: { tenant_id_role_name: { tenant_id: tenantId, role_name: 'InventoryManager' } },
    create: { role_id: roleId, tenant_id: tenantId, role_name: 'InventoryManager' },
    update: {}
  });

  // Setup Permission explicitly
  await prisma.auth_role_permissions.upsert({
    where: { tenant_id_role_id_resource_action: { tenant_id: tenantId, role_id: roleId, resource: 'Inventory:StockMovement', action: 'CREATE' } },
    create: { tenant_id: tenantId, role_id: roleId, resource: 'Inventory:StockMovement', action: 'CREATE', effect: 'PERMIT' },
    update: { effect: 'PERMIT' }
  });

  // Setup User Role
  const userId = 'user-has-access';
  await prisma.auth_user_roles.upsert({
    where: { tenant_id_user_id_role_id: { tenant_id: tenantId, user_id: userId, role_id: roleId } },
    create: { tenant_id: tenantId, user_id: userId, role_id: roleId },
    update: {}
  });
  
  // Setup User Without Access
  const noAccessUserId = 'user-no-access';

  // Setup Accounts for Journal
  await prisma.chart_of_accounts.upsert({
    where: { account_id: 'inventory-asset' },
    create: { account_id: 'inventory-asset', tenant_id: tenantId, account_name: 'Inventory', account_type: 'INVENTORY' },
    update: { account_type: 'INVENTORY' }
  });
  await prisma.chart_of_accounts.upsert({
    where: { account_id: 'cogs' },
    create: { account_id: 'cogs', tenant_id: tenantId, account_name: 'Cost of Goods Sold', account_type: 'COGS' },
    update: { account_type: 'COGS' }
  });
}

async function runTests() {
  console.log('--- CONTROLLED FIRST EXECUTION TESTS ---\\n');
  const prisma = getPrisma();
  const uow = new UnitOfWork(prisma);
  const useCase = new PostStockMovementUseCase(uow);
  const authz = new AuthzKernel(prisma);
  
  const tenantId = '00000000-0000-0000-0000-000000000001';
  await setupTestData(tenantId);

  // ----------------------------------------------------
  // TEST 1: AuthZ Path (User without InventoryManager role)
  // ----------------------------------------------------
  console.log('Test 1: AuthZ Path (Reject before DB)');
  try {
    const isAuthorized = await authz.evaluate(tenantId, 'user-no-access', 'Inventory:StockMovement', 'CREATE');
    if (!isAuthorized) {
      console.log('✅ PASS: Unauthorized user rejected.');
    } else {
      console.log('❌ FAIL: Unauthorized user allowed.');
    }
  } catch (e) {
    if (e.message.includes('NOT_AUTHORIZED')) {
      console.log('✅ PASS: Unauthorized user rejected with throw.');
    } else {
      console.log('❌ FAIL: Unexpected error', e);
    }
  }

  // ----------------------------------------------------
  // TEST 2: Failure Path (Rollback)
  // ----------------------------------------------------
  console.log('\\nTest 2: Failure Path (Rollback on Invalid Data)');
  const correlationId2 = randomUUID();
  try {
    await useCase.execute({
      warehouse_id: 'a9844e13-3ef4-4f01-995b-240ffed3293e',
      item_id: '7ed77cd3-5b82-411a-abdf-f739662b2ac1',
      quantity: 0,
      movement_type: 'receipt',
      contextBundle: { tenant_id: tenantId, user_id: 'user-has-access', correlation_id: correlationId2 }
    });
    console.log('❌ FAIL: Should have thrown validation error.');
  } catch (e) {
    console.log('✅ PASS: Validation/Tx Error caught.', e.code || e.message);
  }
  
  // Verify Rollback
  const entries2 = await prisma.journal_entries.findMany({ where: { correlation_id: correlationId2 }});
  if (entries2.length === 0) {
    console.log('✅ PASS: No journal entry created (Transaction Rolled Back or Blocked safely).');
  } else {
    console.log('❌ FAIL: Journal entry exists for failed tx!');
  }

  // ----------------------------------------------------
  // TEST 3: Success Path
  // ----------------------------------------------------
  console.log('\\nTest 3: Success Path (Valid Stock Movement -> Journal Entry -> Outbox Event)');
  const correlationId3 = randomUUID();
  try {
    // Note: User must be authorized (which they are)
    const isAuthorized = await authz.evaluate(tenantId, 'user-has-access', 'Inventory:StockMovement', 'CREATE');
    if (!isAuthorized) throw new Error('Auth failed for valid user');

    await useCase.execute({
      warehouse_id: 'a9844e13-3ef4-4f01-995b-240ffed3293e',
      item_id: '7ed77cd3-5b82-411a-abdf-f739662b2ac1',
      quantity: 10,
      movement_type: 'receipt',
      contextBundle: { tenant_id: tenantId, user_id: 'user-has-access', correlation_id: correlationId3 }
    });
    console.log('✅ PASS: Use case executed successfully.');
  } catch (e) {
    console.log('❌ FAIL: Use case failed.', e);
  }

  // Verify DB Changes
  const stockMovements = await prisma.stock_movements.findMany({ where: { correlation_id: correlationId3 }});
  const journals = await prisma.journal_entries.findMany({ where: { correlation_id: correlationId3 }});
  const lines = journals.length > 0 ? await prisma.journal_lines.findMany({ where: { journal_id: journals[0].journal_id }}) : [];
  const outbox = await prisma.outbox_events.findMany({ where: { correlation_id: correlationId3 }});

  if (stockMovements.length > 0) console.log('✅ PASS: Stock movement recorded.');
  else console.log('❌ FAIL: Missing stock movement.');

  if (journals.length > 0) console.log('✅ PASS: Journal Entry created.');
  else console.log('❌ FAIL: Missing Journal Entry.');

  if (lines.length >= 2) {
    const totalDebit = lines.reduce((sum, l) => sum + Number(l.debit_amount), 0);
    const totalCredit = lines.reduce((sum, l) => sum + Number(l.credit_amount), 0);
    if (totalDebit === totalCredit) {
      console.log('✅ PASS: Journal is balanced (Debit = Credit)');
    } else {
      console.log('❌ FAIL: Journal is unbalanced!');
    }
  } else {
    console.log('❌ FAIL: Insufficient Journal Lines.');
  }

  if (outbox.length > 0) console.log('✅ PASS: Outbox event emitted.');
  else console.log('❌ FAIL: Missing Outbox event.');

}

runTests().then(() => {
  console.log('\\n--- TESTS COMPLETED ---');
  process.exit(0);
}).catch(console.error);
