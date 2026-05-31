import express from 'express';
import bodyParser from 'body-parser';
import stockMovementRouter from './gateway/routes/stock-movement.route';
import { ContractError } from './gateway/error_handler/contract-error';

const app = express();
const PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;

// 1. Global Middleware Chain (Strict Order)
app.use(bodyParser.json());

// 2. Route Registration (Phase 15 Slice Only)
app.use('/api/v1', stockMovementRouter);

// 3. Global Error Handler (INV-ERROR-CONTAINMENT)
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  if (err instanceof ContractError) {
    return res.status((err as any).statusCode || 400).json({
      success: false,
      error: err.code,
      message: err.message,
      details: err.details || null
    });
  }
  // Fallback for unhandled structural errors (never exposes stack)
  console.error('[SYS-ERR]', err.message);
  res.status(500).json({ 
    success: false, 
    error: 'INTERNAL_CONSTRAINT_VIOLATION', 
    message: 'Request processing halted by system guard.' 
  });
});

// 4. Bootstrap Execution (No business logic, only runtime wiring)
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[BOOTSTRAP] Execution slice active on port ${PORT}. Awaiting authenticated requests.`);
});

export default app;
