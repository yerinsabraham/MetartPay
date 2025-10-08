import { Request, Response } from 'express';
import { db } from '../index';
import { PaymentLink, CreatePaymentLinkRequest } from '../models/types';
import { WalletService } from '../services/walletService';
import QRCode from 'qrcode';

export class PaymentLinkController {
  private walletService = new WalletService();

  /**
   * Create a new payment link for a merchant
   */
  async createPaymentLink(req: Request, res: Response): Promise<void> {
    try {
      const { merchantId } = req.params;
      const createRequest: CreatePaymentLinkRequest = req.body;

      // Validate merchant exists and has wallets
      const merchantRef = db.collection('merchants').doc(merchantId);
      const merchantSnap = await merchantRef.get();
      
      if (!merchantSnap.exists) {
        res.status(404).json({ error: 'Merchant not found' });
        return;
      }

      const merchantData = merchantSnap.data();
      if (!merchantData?.walletsGenerated) {
        res.status(400).json({ error: 'Merchant wallets not generated yet' });
        return;
      }

      // Get merchant wallets
      const walletsSnap = await db.collection('wallets')
        .where('merchantId', '==', merchantId)
        .get();

      if (walletsSnap.empty) {
        res.status(400).json({ error: 'No wallets found for merchant' });
        return;
      }

      const wallets = walletsSnap.docs.map(doc => ({ 
        id: doc.id, 
        ...doc.data() 
      })) as Array<{ id: string; chain: string; publicAddress: string; merchantId: string }>;

      // Get current crypto prices
      const cryptoPrices = await this.getCryptoPrices();

      // Create crypto options for each network/token combination
      const cryptoOptions: PaymentLink['cryptoOptions'] = [];

      for (const network of createRequest.networks) {
        for (const token of createRequest.tokens) {
          const wallet = wallets.find(w => w.chain === network);
          if (wallet) {
            const priceKey = token.toLowerCase();
            const cryptoPrice = cryptoPrices[priceKey];
            
            if (cryptoPrice) {
              const cryptoAmount = createRequest.amount / cryptoPrice; // Convert NGN to crypto
              
              cryptoOptions.push({
                network,
                token,
                address: wallet.publicAddress,
                amount: parseFloat(cryptoAmount.toFixed(6)) // 6 decimal places for crypto
              });
            }
          }
        }
      }

      if (cryptoOptions.length === 0) {
        res.status(400).json({ error: 'No valid crypto options could be generated' });
        return;
      }

      // Create payment link
      const paymentLinkData: Omit<PaymentLink, 'id'> = {
        merchantId,
        title: createRequest.title,
        description: createRequest.description,
        amount: createRequest.amount,
        currency: 'NGN',
        cryptoOptions,
        expiresAt: createRequest.expiresAt ? new Date(createRequest.expiresAt) : undefined,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
        totalPayments: 0,
        totalAmountReceived: 0
      };

      const paymentLinkRef = await db.collection('paymentLinks').add(paymentLinkData);
      
      const paymentLink: PaymentLink = {
        id: paymentLinkRef.id,
        ...paymentLinkData
      };

      res.status(201).json({
        success: true,
        paymentLink,
        paymentUrl: `${process.env.FRONTEND_URL}/pay/${paymentLinkRef.id}`
      });

    } catch (error) {
      console.error('Error creating payment link:', error);
      res.status(500).json({ 
        error: 'Failed to create payment link',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Get payment links for a merchant
   */
  async getPaymentLinks(req: Request, res: Response): Promise<void> {
    try {
      const { merchantId } = req.params;
      const { status, limit = 20 } = req.query;

      let query = db.collection('paymentLinks')
        .where('merchantId', '==', merchantId)
        .orderBy('createdAt', 'desc');

      if (status && status !== 'all') {
        query = query.where('status', '==', status);
      }

      query = query.limit(parseInt(limit as string));

      const snapshot = await query.get();
      
      const paymentLinks: PaymentLink[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as PaymentLink));

      res.json({
        success: true,
        paymentLinks,
        count: paymentLinks.length
      });

    } catch (error) {
      console.error('Error fetching payment links:', error);
      res.status(500).json({ 
        error: 'Failed to fetch payment links',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Get a specific payment link (public endpoint for customers)
   */
  async getPaymentLink(req: Request, res: Response): Promise<void> {
    try {
      const { linkId } = req.params;
      const { network, token } = req.query;

      const paymentLinkSnap = await db.collection('paymentLinks').doc(linkId).get();
      
      if (!paymentLinkSnap.exists) {
        res.status(404).json({ error: 'Payment link not found' });
        return;
      }

      const paymentLink: PaymentLink = {
        id: paymentLinkSnap.id,
        ...paymentLinkSnap.data()
      } as PaymentLink;

      // Check if link is expired
      if (paymentLink.expiresAt && new Date() > paymentLink.expiresAt) {
        await db.collection('paymentLinks').doc(linkId).update({
          status: 'expired',
          updatedAt: new Date()
        });
        paymentLink.status = 'expired';
      }

      // If specific network/token is requested, start monitoring
      if (network && token && paymentLink.status === 'active') {
        const cryptoOption = paymentLink.cryptoOptions.find(
          opt => opt.network === network && opt.token === token
        );

        if (cryptoOption) {
          // Check if monitoring is already active for this address
          const existingMonitoring = await db.collection('monitoredAddresses')
            .where('paymentLinkId', '==', linkId)
            .where('address', '==', cryptoOption.address.toLowerCase())
            .where('status', '==', 'active')
            .limit(1)
            .get();

          if (existingMonitoring.empty) {
            // Start monitoring this address
            await db.collection('monitoredAddresses').add({
              merchantId: paymentLink.merchantId,
              paymentLinkId: linkId,
              address: cryptoOption.address.toLowerCase(),
              network: cryptoOption.network,
              token: cryptoOption.token,
              expectedAmount: cryptoOption.amount,
              expiresAt: paymentLink.expiresAt,
              status: 'active',
              lastCheckedBlock: 0, // Will be updated by monitoring service
              createdAt: new Date(),
              updatedAt: new Date(),
            });

            console.log(`Started monitoring ${cryptoOption.address} for ${cryptoOption.amount} ${cryptoOption.token}`);
          }
        }
      }

      // Get merchant info for display
      const merchantSnap = await db.collection('merchants').doc(paymentLink.merchantId).get();
      const merchantData = merchantSnap.data();

      res.json({
        success: true,
        paymentLink,
        merchant: {
          businessName: merchantData?.businessName || 'Business'
        }
      });

    } catch (error) {
      console.error('Error fetching payment link:', error);
      res.status(500).json({ 
        error: 'Failed to fetch payment link',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Generate QR code for payment link
   */
  async generateQRCode(req: Request, res: Response): Promise<void> {
    try {
      const { linkId } = req.params;
      const { network, token } = req.query;

      const paymentLinkSnap = await db.collection('paymentLinks').doc(linkId).get();
      
      if (!paymentLinkSnap.exists) {
        res.status(404).json({ error: 'Payment link not found' });
        return;
      }

      const paymentLink = paymentLinkSnap.data() as PaymentLink;

      // Find the crypto option for the specified network and token
      const cryptoOption = paymentLink.cryptoOptions.find(
        opt => opt.network === network && opt.token === token
      );

      if (!cryptoOption) {
        res.status(400).json({ error: 'Invalid network/token combination' });
        return;
      }

      // Create payment URL for QR code
      const paymentUrl = `${process.env.FRONTEND_URL}/pay/${linkId}?network=${network}&token=${token}`;
      
      // Generate QR code
      const qrCodeData = await QRCode.toDataURL(paymentUrl, {
        width: 256,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      });

      res.json({
        success: true,
        qrCode: qrCodeData,
        paymentUrl,
        cryptoOption
      });

    } catch (error) {
      console.error('Error generating QR code:', error);
      res.status(500).json({ 
        error: 'Failed to generate QR code',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Update payment link status
   */
  async updatePaymentLink(req: Request, res: Response): Promise<void> {
    try {
      const { linkId } = req.params;
      const { status } = req.body;

      if (!['active', 'inactive', 'expired'].includes(status)) {
        res.status(400).json({ error: 'Invalid status' });
        return;
      }

      await db.collection('paymentLinks').doc(linkId).update({
        status,
        updatedAt: new Date()
      });

      res.json({
        success: true,
        message: 'Payment link updated successfully'
      });

    } catch (error) {
      console.error('Error updating payment link:', error);
      res.status(500).json({ 
        error: 'Failed to update payment link',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Delete payment link
   */
  async deletePaymentLink(req: Request, res: Response): Promise<void> {
    try {
      const { linkId } = req.params;

      await db.collection('paymentLinks').doc(linkId).delete();

      res.json({
        success: true,
        message: 'Payment link deleted successfully'
      });

    } catch (error) {
      console.error('Error deleting payment link:', error);
      res.status(500).json({ 
        error: 'Failed to delete payment link',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Get current cryptocurrency prices in NGN
   */
  private async getCryptoPrices(): Promise<Record<string, number>> {
    try {
      const response = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=tether,usd-coin&vs_currencies=ngn');
      const data = await response.json() as Record<string, Record<string, number>>;
      
      return {
        usdt: data.tether?.ngn || 1650, // Fallback to ~1650 NGN per USDT
        usdc: data['usd-coin']?.ngn || 1650 // Fallback to ~1650 NGN per USDC
      };
    } catch (error) {
      console.error('Error fetching crypto prices:', error);
      // Return fallback prices
      return {
        usdt: 1650, // ~1650 NGN per USDT
        usdc: 1650  // ~1650 NGN per USDC
      };
    }
  }
}