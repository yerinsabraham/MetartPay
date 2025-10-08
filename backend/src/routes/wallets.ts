import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import {
  generateMerchantWallets,
  getMerchantWallets,
  getWalletBalances,
} from '../controllers/walletController';

const router = Router();

// All wallet routes require authentication
router.use(authenticateToken);

// POST /api/wallets/generate/:merchantId - Generate wallets for merchant
router.post('/generate/:merchantId', generateMerchantWallets);

// GET /api/wallets/merchant/:merchantId - Get merchant wallets
router.get('/merchant/:merchantId', getMerchantWallets);

// GET /api/wallets/balances/:merchantId - Get wallet balances
router.get('/balances/:merchantId', getWalletBalances);

export default router;