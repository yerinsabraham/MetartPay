import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { asyncHandler } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';
import { walletService } from '../services/walletService';
import { Wallet, Merchant } from '../models/types';

/**
 * Generate wallets for a merchant after KYC approval
 */
export const generateMerchantWallets = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { merchantId } = req.params;

    // Get merchant details
    const merchantDoc = await db.collection('merchants').doc(merchantId).get();
    
    if (!merchantDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Merchant not found',
      });
    }

    const merchant = merchantDoc.data() as Merchant;

    // Check permissions (user owns merchant or is admin)
    if (merchant.userId !== req.user?.uid && !req.user?.admin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    // Check if KYC is verified
    if (merchant.kycStatus !== 'verified') {
      return res.status(400).json({
        success: false,
        message: 'KYC must be verified before generating wallets',
      });
    }

    // Check if wallets already exist
    const existingWallets = await db
      .collection('wallets')
      .where('merchantId', '==', merchantId)
      .get();

    if (!existingWallets.empty) {
      return res.status(400).json({
        success: false,
        message: 'Wallets already exist for this merchant',
        data: existingWallets.docs.map(doc => doc.data()),
      });
    }

    try {
      // Generate wallets for each blockchain
      const chains: Array<'ETH' | 'BSC' | 'SOL'> = ['ETH', 'BSC', 'SOL'];
      const wallets: Wallet[] = [];

      for (const chain of chains) {
        // Use merchant ID hash as a consistent derivation index
        const derivationIndex = Math.abs(merchantId.split('').reduce((a, b) => {
          a = ((a << 5) - a) + b.charCodeAt(0);
          return a & a;
        }, 0));

        // Generate address for this chain
        const { address } = await walletService.generateInvoiceAddress(
          chain,
          derivationIndex
        );

        // Create wallet record
        const wallet: Wallet = {
          id: uuidv4(),
          chain,
          publicAddress: address,
          merchantId,
          metadata: {
            derivationIndex,
            generatedAt: new Date().toISOString(),
          },
          createdAt: new Date(),
        };

        // Save wallet to database
        await db.collection('wallets').doc(wallet.id).set(wallet);
        wallets.push(wallet);
      }

      // Update merchant with wallet generation status
      await db.collection('merchants').doc(merchantId).update({
        walletsGenerated: true,
        walletsGeneratedAt: new Date(),
        updatedAt: new Date(),
      });

      res.status(201).json({
        success: true,
        message: 'Wallets generated successfully',
        data: wallets,
      });

    } catch (error) {
      console.error('Error generating wallets:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to generate wallets',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
);

/**
 * Get wallets for a merchant
 */
export const getMerchantWallets = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { merchantId } = req.params;

    // Get merchant to check permissions
    const merchantDoc = await db.collection('merchants').doc(merchantId).get();
    
    if (!merchantDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Merchant not found',
      });
    }

    const merchant = merchantDoc.data() as Merchant;

    // Check permissions
    if (merchant.userId !== req.user?.uid && !req.user?.admin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    // Get wallets
    const walletsSnapshot = await db
      .collection('wallets')
      .where('merchantId', '==', merchantId)
      .get();

    const wallets = walletsSnapshot.docs.map(doc => doc.data() as Wallet);

    res.status(200).json({
      success: true,
      data: wallets,
    });
  }
);

/**
 * Get wallet balances for a merchant
 */
export const getWalletBalances = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { merchantId } = req.params;

    // Get merchant to check permissions
    const merchantDoc = await db.collection('merchants').doc(merchantId).get();
    
    if (!merchantDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Merchant not found',
      });
    }

    const merchant = merchantDoc.data() as Merchant;

    // Check permissions
    if (merchant.userId !== req.user?.uid && !req.user?.admin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    try {
      // Get wallets
      const walletsSnapshot = await db
        .collection('wallets')
        .where('merchantId', '==', merchantId)
        .get();

      const wallets = walletsSnapshot.docs.map(doc => doc.data() as Wallet);

      if (wallets.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No wallets found for this merchant',
        });
      }

      // Get balances for each wallet
      const balances = [];

      for (const wallet of wallets) {
        try {
          // Get native balance
          const nativeBalance = await walletService.getBalance(
            wallet.publicAddress,
            wallet.chain
          );

          // Get USDT balance
          const usdtBalance = await walletService.getBalance(
            wallet.publicAddress,
            wallet.chain,
            'USDT'
          );

          // Get USDC balance
          const usdcBalance = await walletService.getBalance(
            wallet.publicAddress,
            wallet.chain,
            'USDC'
          );

          balances.push({
            chain: wallet.chain,
            address: wallet.publicAddress,
            nativeBalance,
            tokens: {
              USDT: usdtBalance,
              USDC: usdcBalance,
            },
          });
        } catch (error) {
          console.error(`Error getting balance for ${wallet.publicAddress}:`, error);
          balances.push({
            chain: wallet.chain,
            address: wallet.publicAddress,
            error: 'Failed to fetch balance',
          });
        }
      }

      res.status(200).json({
        success: true,
        data: balances,
      });

    } catch (error) {
      console.error('Error fetching wallet balances:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch wallet balances',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
);

/**
 * Auto-generate wallets when KYC is approved (internal function)
 */
export const autoGenerateWalletsOnKYCApproval = async (merchantId: string): Promise<boolean> => {
  try {
    // Check if wallets already exist
    const existingWallets = await db
      .collection('wallets')
      .where('merchantId', '==', merchantId)
      .get();

    if (!existingWallets.empty) {
      console.log(`Wallets already exist for merchant ${merchantId}`);
      return true;
    }

    // Generate wallets for each blockchain
    const chains: Array<'ETH' | 'BSC' | 'SOL'> = ['ETH', 'BSC', 'SOL'];
    const wallets: Wallet[] = [];

    for (const chain of chains) {
      // Use merchant ID hash as a consistent derivation index
      const derivationIndex = Math.abs(merchantId.split('').reduce((a, b) => {
        a = ((a << 5) - a) + b.charCodeAt(0);
        return a & a;
      }, 0));

      // Generate address for this chain
      const { address } = await walletService.generateInvoiceAddress(
        chain,
        derivationIndex
      );

      // Create wallet record
      const wallet: Wallet = {
        id: uuidv4(),
        chain,
        publicAddress: address,
        merchantId,
        metadata: {
          derivationIndex,
          generatedAt: new Date().toISOString(),
          autoGenerated: true,
        },
        createdAt: new Date(),
      };

      // Save wallet to database
      await db.collection('wallets').doc(wallet.id).set(wallet);
      wallets.push(wallet);
    }

    // Update merchant with wallet generation status
    await db.collection('merchants').doc(merchantId).update({
      walletsGenerated: true,
      walletsGeneratedAt: new Date(),
      updatedAt: new Date(),
    });

    console.log(`Successfully generated ${wallets.length} wallets for merchant ${merchantId}`);
    return true;

  } catch (error) {
    console.error(`Error auto-generating wallets for merchant ${merchantId}:`, error);
    return false;
  }
};