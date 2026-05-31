import { TransactionClient } from '../../../infrastructure/database/unit-of-work.impl';
import { ContractError } from '../../../gateway/error_handler/contract-error';

export class JournalPosterImpl {
  async post(tx: TransactionClient, dto: any) {
    const debit = Math.abs(dto.quantity) * 10; // Default evaluation for MVP
    const credit = debit;

    if (debit !== credit) {
      throw new ContractError('IMBALANCE_VIOLATION', 'Debit must equal Credit');
    }

    const journalId = dto.contextBundle.correlation_id;

    await tx.$executeRaw`
      INSERT INTO journal_entries (journal_id, tenant_id, correlation_id, journal_date, description, status)
      VALUES (
        ${journalId},
        ${dto.contextBundle.tenant_id}::uuid,
        ${journalId}::uuid,
        CURRENT_DATE,
        ${`Stock ${dto.movement_type}: ${dto.item_id}`},
        'posted'
      )
    `;

    await tx.$executeRaw`
      INSERT INTO journal_lines (tenant_id, journal_id, account_id, debit_amount, credit_amount, transaction_currency, exchange_rate, base_debit_amount, base_credit_amount)
      VALUES 
        (${dto.contextBundle.tenant_id}::uuid, ${journalId}, 'ASSET_INVENTORY_ACC', ${debit}, 0, 'EGP', 1, ${debit}, 0),
        (${dto.contextBundle.tenant_id}::uuid, ${journalId}, 'EXPENSE_COGS_ACC', 0, ${credit}, 'EGP', 1, 0, ${credit})
    `;
  }
}
