import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { asyncHandler } from '../middleware/errorHandler';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';
import { CreateMerchantRequest, Merchant } from '../models/types';
import { autoGenerateWalletsOnKYCApproval } from '../controllers/walletController';

const router = Router();

// POST /api/merchants - Create new merchant
router.post('/', asyncHandler(async (req: Request, res: Response) => {
  const {
    userId,
    businessName,
    bankAccountNumber,
    bankName,
    bankAccountName,
  }: CreateMerchantRequest = req.body;

  // Validation
  if (!userId || !businessName || !bankAccountNumber || !bankName || !bankAccountName) {
    return res.status(400).json({
      success: false,
      message: 'All merchant fields are required',
    });
  }

  const merchantId = uuidv4();
  const merchant: Merchant = {
    id: merchantId,
    userId,
    businessName,
    bankAccountNumber,
    bankName,
    bankAccountName,
    kycStatus: 'pending',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  await db.collection('merchants').doc(merchantId).set(merchant);

  res.status(201).json({
    success: true,
    data: merchant,
    message: 'Merchant created successfully',
  });
}));

// GET /api/merchants/:id - Get merchant details
router.get('/:id', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;

  const doc = await db.collection('merchants').doc(id).get();
  
  if (!doc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Merchant not found',
    });
  }

  const merchant = doc.data() as Merchant;

  // Check if user owns this merchant or is admin
  if (merchant.userId !== req.user?.uid && !req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }

  res.status(200).json({
    success: true,
    data: merchant,
  });
}));

// PUT /api/merchants/:id - Update merchant details
router.put('/:id', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const updates = req.body;

  // Get existing merchant
  const doc = await db.collection('merchants').doc(id).get();
  
  if (!doc.exists) {
    return res.status(404).json({
      success: false,
      message: 'Merchant not found',
    });
  }

  const merchant = doc.data() as Merchant;

  // Check permissions
  if (merchant.userId !== req.user?.uid && !req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }

  // Check if KYC status is being updated to 'verified'
  const kycStatusChanged = updates.kycStatus && updates.kycStatus !== merchant.kycStatus;
  const kycApproved = updates.kycStatus === 'verified';

  // Update merchant
  const updatedMerchant = {
    ...merchant,
    ...updates,
    updatedAt: new Date(),
  };

  await db.collection('merchants').doc(id).update(updatedMerchant);

  // Auto-generate wallets if KYC was just approved
  if (kycStatusChanged && kycApproved) {
    console.log(`KYC approved for merchant ${id}, generating wallets...`);
    try {
      await autoGenerateWalletsOnKYCApproval(id);
    } catch (error) {
      console.error(`Failed to auto-generate wallets for merchant ${id}:`, error);
      // Don't fail the request if wallet generation fails
    }
  }

  res.status(200).json({
    success: true,
    data: updatedMerchant,
    message: 'Merchant updated successfully',
  });
}));

// GET /api/merchants/user/:userId - Get merchants by user ID
router.get('/user/:userId', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { userId } = req.params;

  // Check if user is requesting their own merchants or is admin
  if (userId !== req.user?.uid && !req.user?.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied',
    });
  }

  const snapshot = await db
    .collection('merchants')
    .where('userId', '==', userId)
    .get();

  const merchants = snapshot.docs.map(doc => doc.data() as Merchant);

  res.status(200).json({
    success: true,
    data: merchants,
  });
}));

export default router;