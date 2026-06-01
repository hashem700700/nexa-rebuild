import { Router, Request, Response, NextFunction } from 'express';
import { getPrisma } from '../../lib/prisma';
import { authzPreFlight } from '../middleware/authz-preflight';
import { PostStockMovementUseCase } from '../../domains/inventory/use-cases/post-stock-movement.impl';
import { UnitOfWork } from '../../infrastructure/database/unit-of-work.impl';
import { ContractError } from '../error_handler/contract-error';

const router = Router();

// INV-GATEWAY-ENFORCE: كل route معزول بـ AuthZ Pre-Flight
router.post(
  '/stock-movements',
  authzPreFlight('inventory', 'POST_MOVEMENT'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uow = new UnitOfWork(getPrisma());
      const useCase = new PostStockMovementUseCase(uow);
      
      const result = await useCase.execute({
        ...req.body,
        contextBundle: (req as any).contextBundle! // مُحقن من الـ Middleware
      });

      res.status(201).json({ success: true, data: result });
    } catch (err: any) {
      // INV-ERROR-CONTAINMENT: منع تسرب التفاصيل التقنية
      next(new ContractError(err.message || 'Unknown error'));
    }
  }
);

export default router;
