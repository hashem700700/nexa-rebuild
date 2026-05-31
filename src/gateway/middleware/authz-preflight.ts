import { Request, Response, NextFunction } from 'express';
import { ContractError } from '../error_handler/contract-error';

// SoD Rules: Array of mutually exclusive roles
const SoD_CONFLICTS = [
  ['InventoryManager', 'AccountPayable'],
  ['Sales', 'Approver']
];

export const authzPreFlight = (req: Request, res: Response, next: NextFunction) => {
  try {
    const tenantId = req.header('X-Tenant-Id');
    const userId = req.header('X-User-Id');
    const correlationId = req.header('X-Correlation-Id');
    const rolesHeader = req.header('X-Roles') || '';
    
    if (!tenantId || !userId || !correlationId) {
      throw new ContractError('MISSING_CONTEXT', 'Tenant, User, and Correlation IDs are required');
    }

    const userRoles = rolesHeader.split(',').map(r => r.trim()).filter(Boolean);

    // 1. RBAC Enforcer (Must have domain matching role)
    if (!userRoles.includes('InventoryManager')) {
      throw new ContractError('AUTHZ_DENIED', 'Missing required role: InventoryManager');
    }

    // 2. SoD Conflict Resolver
    for (const conflict of SoD_CONFLICTS) {
      const hasConflict = conflict.every(role => userRoles.includes(role));
      if (hasConflict) {
        throw new ContractError('SOD_CONFLICT', `Segregation of Duties violation: User cannot hold both ${conflict.join(' and ')}`);
      }
    }

    // 3. Attach ContextBundle
    (req as any).contextBundle = {
      tenant_id: tenantId,
      user_id: userId,
      correlation_id: correlationId,
      roles: userRoles
    };

    next();
  } catch (err: any) {
    if (err instanceof ContractError) {
      return res.status(403).json({
        success: false,
        error: err.code,
        message: err.message
      });
    }
    next(err);
  }
};
