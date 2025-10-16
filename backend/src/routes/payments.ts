import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { PaymentLinkController } from '../controllers/paymentLinkController';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';

const router = Router();
const paymentLinkController = new PaymentLinkController();

// GET /api/payments/status/:invoiceId - Check payment status
router.get('/status/:invoiceId', asyncHandler(async (req: Request, res: Response) => {
  // This endpoint will be used to check if payment has been received
  res.status(200).json({
    success: true,
    message: 'Payment status endpoint - implementation pending',
  });
}));

// POST /api/payments/create - Create a payment (server-side) for a merchant
router.post('/create', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  // Log incoming request payload (trimmed) for debugging failing networks like TRON
  try {
    const incoming = {
      body: {
        merchantId: req.body?.merchantId,
        amountNgn: req.body?.amountNgn,
        token: req.body?.token,
        network: req.body?.network,
      },
      headers: {
        authorization: req.headers?.authorization ? req.headers.authorization.toString().slice(0, 20) + '...[redacted]' : undefined,
        'user-agent': req.headers['user-agent']
      },
      uid: req.user?.uid
    };
    console.info('[payments.create] incoming request:', JSON.stringify(incoming));
  } catch (logErr) {
    console.warn('[payments.create] failed to log incoming request:', logErr);
  }

  // Expected body: { merchantId, amountNgn, token, network, description }
  const { merchantId, amountNgn, token, network, description } = req.body;
  if (!merchantId || !amountNgn || !token || !network) {
    res.status(400).json({ success: false, error: 'Missing required fields' });
    return;
  }

  // Verify that the authenticated user owns the merchant or is admin
  const merchantDoc = await db.collection('merchants').doc(merchantId).get();
  if (!merchantDoc.exists) {
    return res.status(404).json({ success: false, error: 'Merchant not found' });
  }
  const merchant = merchantDoc.data();
  if (!merchant) {
    return res.status(404).json({ success: false, error: 'Merchant not found' });
  }
  const uid = req.user?.uid;
  const isAdmin = req.user?.admin;
  if (merchant.userId !== uid && !isAdmin) {
    return res.status(403).json({ success: false, error: 'Forbidden: not authorized for this merchant' });
  }

  // Use the PaymentLinkController to construct crypto options and persist a payment-like record
  try {
    // Reuse createPaymentLink logic partially by building a minimal payment document
    const result = await paymentLinkController.createPaymentForClient({ merchantId, amountNgn, token, network, description });
    res.status(201).json({ success: true, ...result });
  } catch (err: any) {
    console.error('Error creating payment via /create:', err);
    res.status(500).json({ success: false, error: err?.message || 'Failed to create payment' });
  }
}));

export default router;