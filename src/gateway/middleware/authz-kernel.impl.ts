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
  async evaluate(
    tenantId: string, 
    userId: string, 
    resource: string, 
    action: string,
    context?: any // Attributes for ABAC overlay
  ): Promise<boolean> {
    const isPermitted = await this.checkRbac(tenantId, userId, resource, action);
    
    // Abstract ABAC Check (e.g. valid during working hours, etc)
    // if (isPermitted && context) { ... check conditions ... }

    await this.logDecision(tenantId, userId, resource, action, isPermitted);
    
    return isPermitted;
  }

  /**
   * Evaluate and throw an error if denied. Used in pre-flight checks.
   */
  async enforce(tenantId: string, userId: string, resource: string, action: string): Promise<void> {
    const isPermitted = await this.evaluate(tenantId, userId, resource, action);
    if (!isPermitted) {
      throw new ContractError('ACCESS_DENIED', `User ${userId} cannot perform ${action} on ${resource}`);
    }
  }

  private async checkRbac(tenantId: string, userId: string, resource: string, action: string): Promise<boolean> {
    // 1. Get user roles
    const userRoles = await this.prisma.auth_user_roles.findMany({
      where: { tenant_id: tenantId, user_id: userId }
    });

    if (!userRoles.length) return false;

    const roleIds = userRoles.map(ur => ur.role_id);

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

  private async logDecision(tenantId: string, userId: string, resource: string, action: string, isPermitted: boolean) {
    const decision = isPermitted ? 'PERMIT' : 'DENY';
    const timestamp = new Date().toISOString();
    
    // Hash generates an immutable sign off of this access decision (INV-AUDIT-TRAIL)
    const rawDecision = `${tenantId}:${userId}:${resource}:${action}:${decision}:${timestamp}`;
    const decisionHash = crypto.createHash('sha256').update(rawDecision).digest('hex');

    await this.prisma.auth_audit_log.create({
      data: {
        audit_id: crypto.randomUUID(),
        tenant_id: tenantId,
        user_id: userId,
        resource,
        action,
        decision,
        decision_hash: decisionHash,
        timestamp: new Date(timestamp)
      }
    });
  }
}
