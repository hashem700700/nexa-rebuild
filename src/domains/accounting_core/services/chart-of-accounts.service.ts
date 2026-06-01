import { TransactionClient } from '../../../infrastructure/database/unit-of-work.impl';
import { ContractError } from '../../../gateway/error_handler/contract-error';

export class ChartOfAccountsService {
  /**
   * Dynamically resolves the specific account ID for a tenant based on the logical account type.
   * Enforces INV-CHART-OF-ACCOUNTS-GOVERNANCE.
   */
  async getAccountByType(tx: TransactionClient, tenantId: string, accountType: string): Promise<string> {
    const result = await tx.$queryRaw<{account_id: string}[]>`
      SELECT account_id 
      FROM chart_of_accounts 
      WHERE tenant_id = ${tenantId}::uuid 
        AND account_type = ${accountType}
      LIMIT 1
    `;

    if (!result || result.length === 0) {
      throw new ContractError('COA_MAPPING_MISSING', `No account found for tenant mapping type: ${accountType}`);
    }

    return result[0].account_id;
  }
}
