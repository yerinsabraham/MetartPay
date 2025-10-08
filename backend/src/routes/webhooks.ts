import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();

// POST /api/webhooks/transaction - Webhook for transaction notifications
router.post('/transaction', asyncHandler(async (req: Request, res: Response) => {
  const { invoiceId, txHash, chain, token, amount, fromAddress, toAddress } = req.body;

  // This will be called by the blockchain monitoring service
  // when a transaction is detected

  res.status(200).json({
    success: true,
    message: 'Transaction webhook received',
  });
}));

export default router;