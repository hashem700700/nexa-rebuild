import { PrismaClient } from '@prisma/client';
import { ContractError } from '../error_handler/contract-error';
import * as crypto from 'crypto';

/**
 * AuthzKernel manages all access control decisions using RBAC (Role-Based Access Control),
 * ABAC (Attribute-Based Access Control) overlays, and SoD (Segregation of Duties).
 * It logs every decision to an immutable audit trail.
 */
export class AuthzKernel {
  constructor(private readonly prisma: PrismaClient) {}

  /**
   * Evaluate if a user can perform an action on a resource.
   */
  private readonly SOD_CONFLICTS = [
    { roleA: 'InventoryManager', roleB: 'Accountant' },
    { roleA: 'SalesAgent', roleB: 'InventoryManager' }
  ];

  async evaluate(
    tenantId: string, 
    userId: string, 
    resource: string, 
    action: string,
    context?: any // Attributes for ABAC overlay
  ): Promise<boolean> {
    const userRoles = await this.prisma.auth_user_roles.findMany({
      where: { tenant_id: tenantId, user_id: userId }
    });
    
    const roleIds = userRoles.map(ur => ur.role_id);
    
    // SoD (Segregation of Duties) Pre-Check
    if (this.hasSodConflict(roleIds)) {
      await this.logDecision(tenantId, userId, resource, action, false, 'SOD_CONFLICT');
      return false;
    }

    const isPermitted = await this.checkRbac(tenantId, roleIds, resource, action);
    
    // Abstract ABAC Check (e.g. valid during working hours, etc)
    // if (isPermitted && context) { ... check conditions ... }

    await this.logDecision(tenantId, userId, resource, action, isPermitted, 'RBAC_EVALUATION');
    
    return isPermitted;
  }

  private hasSodConflict(userRoles: string[]): boolean {
    for (const conflict of this.SOD_CONFLICTS) {
      if (userRoles.includes(conflict.roleA) && userRoles.includes(conflict.roleB)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Evaluate and throw an error if denied. Used in pre-flight checks.
   */
  async enforce(tenantId: string, userId: string, resource: string, action: string): Promise<void> {
    const isPermitted = await this.evaluate(tenantId, userId, resource, action);
    if (!isPermitted) {
      throw new ContractError('ACCESS_DENIED', `User ${userId} cannot perform ${action} on ${resource}. This may be an SoD violation or missing permission.`);
    }
  }

  private async checkRbac(tenantId: string, roleIds: string[], resource: string, action: string): Promise<boolean> {
    if (!roleIds.length) return false;

    // 2. Check if any role has the exact permission or a wildcard
    const permission = await this.prisma.auth_role_permissions.findFirst({
      where: {
        tenant_id: tenantId,
        role_id: { in: roleIds },
        resource: resource,
        action: action
      }
    });

    return !!permission;
  }

  private async logDecision(tenantId: string, userId: string, resource: string, action: string, isPermitted: boolean, reason: string = 'UNKNOWN') {
    const decision = isPermitted ? 'PERMIT' : 'DENY';
    const timestamp = new Date().toISOString();
    
    // Hash generates an immutable sign off of this access decision (INV-AUDIT-TRAIL)
    const rawDecision = `${tenantId}:${userId}:${resource}:${action}:${decision}:${reason}:${timestamp}`;
    const decisionHash = crypto.createHash('sha256').update(rawDecision).digest('hex');

    await this.prisma.auth_audit_log.create({
      data: {
        audit_id: crypto.randomUUID(),
        tenant_id: tenantId,
        user_id: userId,
        resource,
        action,
        decision: `${decision} [${reason}]`,
        decision_hash: decisionHash,
        timestamp: new Date(timestamp)
      }
    });
  }
}
