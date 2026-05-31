import { Request, Response, NextFunction } from 'express';
import { AuthZKernel, ContextBundle } from '../../domains/authz_kernel/interfaces';

export const authzPreFlight = async (req: Request, res: Response, next: NextFunction) => {
  // 1. استخراج حزمة السياق الإلزامية
  const context: ContextBundle = {
    tenant_id: req.headers['x-tenant-id'] as string,
    correlation_id: req.headers['x-correlation-id'] as string,
    user_id: req.headers['x-user-id'] as string,
    branch_scope: req.headers['x-branch-id'] as string,
    resource: 'inventory:stock_movement',
    action: 'create'
  };

  // 2. رفض الطلب فوراً إذا كانت الحزمة ناقصة (INV-GATEWAY-ENFORCE)
  if (!context.tenant_id || !context.correlation_id || !context.user_id) {
    return res.status(400).json({ error: 'MissingContextBundle', code: 'G0001' });
  }

  // 3. استدعاء واجهة محرك الصلاحيات (Stubbed)
  const decision = await AuthZKernel.evaluate(context);
  
  if (decision.effect === 'deny') {
    return res.status(403).json({ 
      error: 'AuthorizationDenied', 
      code: 'Z0001', 
      reasoning: decision.reasoning_code 
    });
  }

  // 4. تمرير السياق للنطاقات التالية
  (req as any).contextBundle = context;
  next();
};
