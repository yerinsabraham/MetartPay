import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();

// GET /api/payments/status/:invoiceId - Check payment status
router.get('/status/:invoiceId', asyncHandler(async (req: Request, res: Response) => {
  // This endpoint will be used to check if payment has been received
  res.status(200).json({
    success: true,
    message: 'Payment status endpoint - implementation pending',
  });
}));

export default router;