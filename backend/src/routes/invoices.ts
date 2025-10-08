import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import QRCode from 'qrcode';
import { asyncHandler } from '../middleware/errorHandler';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';
import { CreateInvoiceRequest, Invoice } from '../models/types';
import { walletService } from '../services/walletService';

const router = Router();

// POST /api/invoices - Create new invoice
router.post('/', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const {
    merchantId,
    amountNaira,
    chain,
    token,
    metadata = {},
  }: CreateInvoiceRequest = req.body;

  // Validation
  if (!merchantId || !amountNaira || !chain || !token) {
    return res.status(400).json({
      success: false,
      message: 'All invoice fields are required',
    });
  }

  // Verify merchant exists and user has access
  const merchantDoc = await db.collection('merchants').doc(merchantId).get();
  
  if (!merchantDoc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Merchant not found',
    });
  }

  const merchant = merchantDoc.data();
  
  if (merchant?.userId !== req.user?.uid && !req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }

  // Get next derivation index for address generation
  const invoiceCount = await db.collection('invoices')
    .where('merchantId', '==', merchantId)
    .count()
    .get();
  
  const derivationIndex = invoiceCount.data().count;

  // Generate receiving address
  const { address } = await walletService.generateInvoiceAddress(chain, derivationIndex);

  // Convert Naira to crypto
  const amountCrypto = await walletService.convertNairaToCrypto(amountNaira, token);
  const fxRate = await walletService.getCryptoToNairaRate(token);

  // Calculate platform fee (2.5%)
  const feeNaira = amountNaira * 0.025;

  const invoiceId = uuidv4();
  const reference = `INV-${Date.now()}-${invoiceId.slice(0, 8).toUpperCase()}`;

  const invoice: Invoice = {
    id: invoiceId,
    merchantId,
    reference,
    amountNaira,
    amountCrypto,
    cryptoSymbol: token,
    chain,
    receivingAddress: address,
    receivingAddressDerivationIndex: derivationIndex,
    status: 'pending',
    createdAt: new Date(),
    updatedAt: new Date(),
    feeNaira,
    fxRate,
    metadata,
  };

  // Save invoice to database
  await db.collection('invoices').doc(invoiceId).set(invoice);

  // Generate QR code
  let qrData: string;
  if (chain === 'SOL') {
    qrData = `solana:${address}?amount=${amountCrypto}&spl-token=${token}`;
  } else {
    // Ethereum URI format
    qrData = `ethereum:${address}@${chain === 'ETH' ? '1' : '56'}?value=${amountCrypto}`;
  }

  const qrSvg = await QRCode.toString(qrData, {
    type: 'svg',
    width: 256,
    margin: 2,
  });

  // Generate payment URL
  const payUrl = `${process.env.BASE_URL || 'https://metartpay.web.app'}/pay?invoice=${invoiceId}`;

  res.status(201).json({
    success: true,
    data: {
      invoiceId,
      reference,
      payUrl,
      receivingAddress: address,
      amountCrypto: amountCrypto.toFixed(6),
      amountNaira,
      chain,
      cryptoSymbol: token,
      qrSvg,
      expiresIn: '24 hours',
    },
    message: 'Invoice created successfully',
  });
}));

// GET /api/invoices/:id - Get invoice details
router.get('/:id', asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;

  const doc = await db.collection('invoices').doc(id).get();
  
  if (!doc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Invoice not found',
    });
  }

  const invoice = doc.data() as Invoice;

  // Public endpoint - return limited info
  res.status(200).json({
    success: true,
    data: {
      id: invoice.id,
      reference: invoice.reference,
      amountNaira: invoice.amountNaira,
      amountCrypto: invoice.amountCrypto,
      cryptoSymbol: invoice.cryptoSymbol,
      chain: invoice.chain,
      receivingAddress: invoice.receivingAddress,
      status: invoice.status,
      createdAt: invoice.createdAt,
      paidAt: invoice.paidAt,
      txHash: invoice.txHash,
    },
  });
}));

// GET /api/invoices/merchant/:merchantId - Get invoices for merchant
router.get('/merchant/:merchantId', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { merchantId } = req.params;
  const { page = 1, limit = 20, status } = req.query;

  // Verify merchant access
  const merchantDoc = await db.collection('merchants').doc(merchantId).get();
  
  if (!merchantDoc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Merchant not found',
    });
  }

  const merchant = merchantDoc.data();
  
  if (merchant?.userId !== req.user?.uid && !req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }

  // Build query
  let query = db.collection('invoices')
    .where('merchantId', '==', merchantId)
    .orderBy('createdAt', 'desc');

  if (status) {
    query = query.where('status', '==', status);
  }

  // Pagination
  const offset = (Number(page) - 1) * Number(limit);
  query = query.offset(offset).limit(Number(limit));

  const snapshot = await query.get();
  const invoices = snapshot.docs.map(doc => doc.data() as Invoice);

  res.status(200).json({
    success: true,
    data: invoices,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total: snapshot.size,
    },
  });
}));

// PUT /api/invoices/:id/status - Update invoice status (admin only)
router.put('/:id/status', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  if (!req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Admin access required',
    });
  }

  const { id } = req.params;
  const { status, txHash } = req.body;

  const doc = await db.collection('invoices').doc(id).get();
  
  if (!doc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Invoice not found',
    });
  }

  const updates: Partial<Invoice> = {
    status,
    updatedAt: new Date(),
  };

  if (status === 'paid' && txHash) {
    updates.paidAt = new Date();
    updates.txHash = txHash;
  }

  await db.collection('invoices').doc(id).update(updates);

  res.status(200).json({
    success: true,
    message: 'Invoice status updated',
  });
}));

export default router;