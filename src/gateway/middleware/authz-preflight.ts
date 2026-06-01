import { Request, Response, NextFunction } from 'express';
import { ContractError } from '../error_handler/contract-error';
import { getPrisma } from '../../lib/prisma';
import { AuthzKernel } from './authz-kernel.impl';

const authzKernel = new AuthzKernel(getPrisma());

export const authzPreFlight = (resource: string, action: string) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const tenantId = req.header('X-Tenant-Id');
      const userId = req.header('X-User-Id');
      const correlationId = req.header('X-Correlation-Id') || 'temp-id'; // Typically provided or generated
      
      if (!tenantId || !userId) {
        throw new ContractError('MISSING_CONTEXT', 'Tenant and User IDs are required');
      }

      // 1. RBAC Enforcer + ABAC + SoD via Kernel
      await authzKernel.enforce(tenantId, userId, resource, action);

      // 2. Attach ContextBundle
      (req as any).contextBundle = {
        tenant_id: tenantId,
        user_id: userId,
        correlation_id: correlationId
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
};
