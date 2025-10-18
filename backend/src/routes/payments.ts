import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { PaymentLinkController } from '../controllers/paymentLinkController';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';

const router = Router();
const paymentLinkController = new PaymentLinkController();

// DEV-only: POST /api/payments/simulate-confirm - simulate an incoming confirmed transaction
router.post('/simulate-confirm', asyncHandler(async (req: Request, res: Response) => {
  // Only allow in non-production environments
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ success: false, error: 'Not allowed in production' });
  }

  // Require dev simulate key header
  const expectedKey = process.env.DEV_SIMULATE_KEY || 'dev-local-key';
  const providedKey = (req.headers['x-dev-simulate-key'] || '').toString();
  if (providedKey !== expectedKey) {
    return res.status(403).json({ success: false, error: 'Invalid or missing x-dev-simulate-key' });
  }

  const { txHash, toAddress, amountCrypto, cryptoCurrency, network, merchantId, paymentLinkId, fromAddress } = req.body;
  if (!txHash || !toAddress || !amountCrypto || !cryptoCurrency || !network || !merchantId) {
    return res.status(400).json({ success: false, error: 'Missing required fields: txHash,toAddress,amountCrypto,cryptoCurrency,network,merchantId' });
  }

  try {
    const toAddr = toAddress.toString().toLowerCase();

    // Insert a synthetic transaction record (marked confirmed)
    const transaction = {
      paymentLinkId: paymentLinkId || null,
      merchantId,
      txHash: txHash.toString(),
      fromAddress: fromAddress || '',
      toAddress: toAddr,
      amountCrypto: parseFloat(amountCrypto),
      expectedAmount: null,
      cryptoCurrency,
      network,
      blockNumber: req.body.blockNumber || 0,
      confirmations: req.body.confirmations || 999,
      requiredConfirmations: 1,
      status: 'confirmed',
      observedAt: new Date(),
      confirmedAt: new Date(),
      gasUsed: req.body.gasUsed || 0,
      gasPrice: req.body.gasPrice || '0',
      transactionFee: req.body.transactionFee || 0,
      metadata: Object.assign({ synthetic: true }, req.body.metadata || {}),
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const txRef = await db.collection('transactions').add(transaction);

    // Find active monitored addresses that match this destination
    const monitoredSnapshot = await db.collection('monitoredAddresses')
      .where('address', '==', toAddr)
      .where('status', '==', 'active')
      .get();

    const affected: Array<any> = [];

    for (const doc of monitoredSnapshot.docs) {
      const monitored = { id: doc.id, ...doc.data() } as any;

      // Mark monitored address completed
      await db.collection('monitoredAddresses').doc(monitored.id).update({ status: 'completed', updatedAt: new Date() });

      // If linked to a payment link, update totals
      if (monitored.paymentLinkId) {
        const plRef = db.collection('paymentLinks').doc(monitored.paymentLinkId);
        const plDoc = await plRef.get();
        if (plDoc.exists) {
          const cur = plDoc.data() as any;
          await plRef.update({
            totalPayments: (cur?.totalPayments || 0) + 1,
            totalAmountReceived: (cur?.totalAmountReceived || 0) + parseFloat(amountCrypto),
            updatedAt: new Date()
          });
        }
      }

      // Create an in-app notification for merchant
      try {
        await db.collection('notifications').add({
          merchantId: monitored.merchantId,
          type: 'payment_received',
          title: 'Payment Received (SIMULATED)',
          message: `Received ${amountCrypto} ${cryptoCurrency} on ${network}`,
          data: {
            transactionId: txRef.id,
            txHash: txHash.toString(),
            amount: parseFloat(amountCrypto),
            currency: cryptoCurrency,
            network,
          },
          read: false,
          createdAt: new Date(),
        });
      } catch (notifyErr) {
        console.warn('Failed to create simulate notification:', notifyErr);
      }

      affected.push({ monitoredId: monitored.id, paymentLinkId: monitored.paymentLinkId || null });
    }

    return res.status(201).json({ success: true, transactionId: txRef.id, affected });
  } catch (err) {
    console.error('simulate-confirm error:', err);
    return res.status(500).json({ success: false, error: err instanceof Error ? err.message : 'simulate-confirm failed' });
  }

}));

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

  // Basic required fields: merchantId, token and network must always be present
  if (!merchantId || !token || !network) {
    res.status(400).json({ success: false, error: 'Missing required fields: merchantId, token or network' });
    return;
  }

  // For Solana (address-only) flows we allow amountNgn to be missing or zero.
  // For all other networks, require a positive amountNgn.
  const isSolana = typeof network === 'string' && network.toString().toUpperCase().startsWith('SOL');
  if (!isSolana) {
    if (typeof amountNgn !== 'number' || amountNgn <= 0) {
      res.status(400).json({ success: false, error: 'Missing or invalid amountNgn for non-Solana networks' });
      return;
    }
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