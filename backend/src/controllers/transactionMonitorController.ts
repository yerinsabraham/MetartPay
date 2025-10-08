import { Request, Response } from 'express';
import { db } from '../index';
import { BlockchainService } from '../services/blockchainService';
import { Transaction, MonitoredAddress } from '../models/types';

export class TransactionMonitorController {
  private blockchainService = new BlockchainService();

  /**
   * Start monitoring an address for incoming payments
   */
  async startMonitoring(req: Request, res: Response): Promise<void> {
    try {
      const {
        merchantId,
        paymentLinkId,
        address,
        network,
        token,
        expectedAmount,
        expiresAt,
      } = req.body;

      // Validate network and token
      const config = this.blockchainService.getNetworkConfig(network);
      if (!config || !config.tokens[token]) {
        res.status(400).json({ 
          error: `Unsupported network/token combination: ${network}/${token}` 
        });
        return;
      }

      // Get current block number for monitoring baseline
      const currentBlock = await this.blockchainService.getLatestBlockNumber(network);

      // Create monitored address record
      const monitoredAddress: Omit<MonitoredAddress, 'id'> = {
        merchantId,
        paymentLinkId,
        address: address.toLowerCase(),
        network,
        token,
        expectedAmount,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined,
        status: 'active',
        lastCheckedBlock: currentBlock,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const docRef = await db.collection('monitoredAddresses').add(monitoredAddress);

      res.status(201).json({
        success: true,
        monitoringId: docRef.id,
        message: 'Address monitoring started',
      });

    } catch (error) {
      console.error('Error starting monitoring:', error);
      res.status(500).json({ 
        error: 'Failed to start monitoring',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Check for new transactions (called by scheduled function)
   */
  async checkTransactions(req: Request, res: Response): Promise<void> {
    try {
      const { network } = req.query;
      
      if (network && typeof network === 'string') {
        await this.processNetworkTransactions(network);
      } else {
        // Process all networks
        const networks = ['ETH', 'BSC', 'MATIC'];
        await Promise.all(networks.map(net => this.processNetworkTransactions(net)));
      }

      res.json({
        success: true,
        message: 'Transaction check completed',
        timestamp: new Date().toISOString(),
      });

    } catch (error) {
      console.error('Error checking transactions:', error);
      res.status(500).json({ 
        error: 'Transaction check failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Process transactions for a specific network
   */
  private async processNetworkTransactions(network: string): Promise<void> {
    console.log(`Processing transactions for ${network}...`);

    // Get all active monitored addresses for this network
    const monitoredSnapshot = await db.collection('monitoredAddresses')
      .where('network', '==', network)
      .where('status', '==', 'active')
      .get();

    if (monitoredSnapshot.empty) {
      console.log(`No active addresses to monitor on ${network}`);
      return;
    }

    const currentBlock = await this.blockchainService.getLatestBlockNumber(network);

    for (const doc of monitoredSnapshot.docs) {
      const monitored = { id: doc.id, ...doc.data() } as MonitoredAddress;
      
      // Check if expired
      if (monitored.expiresAt && new Date() > monitored.expiresAt) {
        await this.markAddressExpired(monitored.id);
        continue;
      }

      await this.checkAddressTransactions(monitored, currentBlock);
    }
  }

  /**
   * Check transactions for a specific monitored address
   */
  private async checkAddressTransactions(
    monitored: MonitoredAddress, 
    currentBlock: number
  ): Promise<void> {
    try {
      const fromBlock = monitored.lastCheckedBlock + 1;
      
      if (fromBlock > currentBlock) {
        return; // No new blocks to check
      }

      // Get token transfers to this address
      const transfers = await this.blockchainService.getTokenTransfers(
        monitored.network,
        monitored.token,
        monitored.address,
        fromBlock,
        currentBlock
      );

      for (const transfer of transfers) {
        await this.processTransfer(monitored, transfer);
      }

      // Update last checked block
      await db.collection('monitoredAddresses').doc(monitored.id).update({
        lastCheckedBlock: currentBlock,
        updatedAt: new Date(),
      });

    } catch (error) {
      console.error(`Error checking address ${monitored.address}:`, error);
    }
  }

  /**
   * Process an individual token transfer
   */
  private async processTransfer(monitored: MonitoredAddress, transfer: any): Promise<void> {
    try {
      // Check if this transaction is already recorded
      const existingTx = await db.collection('transactions')
        .where('txHash', '==', transfer.txHash)
        .where('toAddress', '==', monitored.address)
        .limit(1)
        .get();

      if (!existingTx.empty) {
        // Transaction already recorded, check for confirmation updates
        const txData = existingTx.docs[0].data();
        if (txData.status !== 'confirmed') {
          await this.updateTransactionStatus(existingTx.docs[0].id, transfer.txHash, monitored.network);
        }
        return;
      }

      // Get transaction details
      const txDetails = await this.blockchainService.getTransactionDetails(
        monitored.network, 
        transfer.txHash
      );

      if (!txDetails || txDetails.status === 0) {
        console.log(`Transaction ${transfer.txHash} failed or not found`);
        return;
      }

      const config = this.blockchainService.getNetworkConfig(monitored.network);
      if (!config) return;

      // Determine transaction status
      let status: Transaction['status'] = 'pending';
      if (txDetails.confirmations >= config.requiredConfirmations) {
        status = 'confirmed';
      } else if (txDetails.confirmations > 0) {
        status = 'confirming';
      }

      // Check if amount is sufficient
      const receivedAmount = parseFloat(transfer.amount);
      if (receivedAmount < monitored.expectedAmount * 0.99) { // 1% tolerance
        status = 'insufficient';
      }

      // Create transaction record
      const transaction: Omit<Transaction, 'id'> = {
        paymentLinkId: monitored.paymentLinkId,
        merchantId: monitored.merchantId,
        txHash: transfer.txHash,
        fromAddress: transfer.fromAddress,
        toAddress: transfer.toAddress,
        amountCrypto: receivedAmount,
        expectedAmount: monitored.expectedAmount,
        cryptoCurrency: monitored.token,
        network: monitored.network,
        blockNumber: transfer.blockNumber,
        confirmations: txDetails.confirmations,
        requiredConfirmations: config.requiredConfirmations,
        status,
        observedAt: new Date(),
        confirmedAt: status === 'confirmed' ? new Date() : undefined,
        gasUsed: parseInt(txDetails.gasUsed),
        gasPrice: txDetails.gasPrice,
        transactionFee: parseFloat(this.blockchainService.calculateTransactionFee(
          txDetails.gasUsed, 
          txDetails.gasPrice
        )),
        metadata: {
          tokenAddress: transfer.tokenAddress,
        },
      };

      const txDoc = await db.collection('transactions').add(transaction);
      
      console.log(`New transaction recorded: ${transfer.txHash} - Status: ${status}`);

      // If confirmed and sufficient, mark payment as complete
      if (status === 'confirmed' && receivedAmount >= monitored.expectedAmount * 0.99) {
        await this.completePayment(monitored, { id: txDoc.id, ...transaction } as Transaction);
      }

    } catch (error) {
      console.error(`Error processing transfer ${transfer.txHash}:`, error);
    }
  }

  /**
   * Update transaction confirmation status
   */
  private async updateTransactionStatus(
    transactionId: string, 
    txHash: string, 
    network: string
  ): Promise<void> {
    try {
      const txDetails = await this.blockchainService.getTransactionDetails(network, txHash);
      if (!txDetails) return;

      const config = this.blockchainService.getNetworkConfig(network);
      if (!config) return;

      let status: Transaction['status'] = 'pending';
      let confirmedAt: Date | undefined;

      if (txDetails.confirmations >= config.requiredConfirmations) {
        status = 'confirmed';
        confirmedAt = new Date();
      } else if (txDetails.confirmations > 0) {
        status = 'confirming';
      }

      await db.collection('transactions').doc(transactionId).update({
        confirmations: txDetails.confirmations,
        status,
        confirmedAt,
        updatedAt: new Date(),
      });

      // If newly confirmed, check if payment should be completed
      if (status === 'confirmed') {
        const txDoc = await db.collection('transactions').doc(transactionId).get();
        const txData = { id: transactionId, ...txDoc.data() } as Transaction;
        
        if (txData.amountCrypto >= txData.expectedAmount * 0.99) {
          // Find the monitored address to complete payment
          const monitoredSnapshot = await db.collection('monitoredAddresses')
            .where('address', '==', txData.toAddress.toLowerCase())
            .where('status', '==', 'active')
            .limit(1)
            .get();

          if (!monitoredSnapshot.empty) {
            const monitored = { 
              id: monitoredSnapshot.docs[0].id, 
              ...monitoredSnapshot.docs[0].data() 
            } as MonitoredAddress;
            
            await this.completePayment(monitored, txData);
          }
        }
      }

    } catch (error) {
      console.error(`Error updating transaction status for ${txHash}:`, error);
    }
  }

  /**
   * Complete a payment and update payment link
   */
  private async completePayment(monitored: MonitoredAddress, transaction: Transaction): Promise<void> {
    try {
      console.log(`Completing payment for ${monitored.paymentLinkId}`);

      // Mark monitored address as completed
      await db.collection('monitoredAddresses').doc(monitored.id).update({
        status: 'completed',
        updatedAt: new Date(),
      });

      // Update payment link if exists
      if (monitored.paymentLinkId) {
        const paymentLinkRef = db.collection('paymentLinks').doc(monitored.paymentLinkId);
        const paymentLinkDoc = await paymentLinkRef.get();
        
        if (paymentLinkDoc.exists) {
          const currentData = paymentLinkDoc.data();
          await paymentLinkRef.update({
            totalPayments: (currentData?.totalPayments || 0) + 1,
            totalAmountReceived: (currentData?.totalAmountReceived || 0) + transaction.amountCrypto,
            updatedAt: new Date(),
          });
        }
      }

      // TODO: Send webhook notification to merchant
      await this.sendPaymentNotification(monitored.merchantId, transaction);

    } catch (error) {
      console.error(`Error completing payment:`, error);
    }
  }

  /**
   * Mark monitored address as expired
   */
  private async markAddressExpired(monitoringId: string): Promise<void> {
    await db.collection('monitoredAddresses').doc(monitoringId).update({
      status: 'expired',
      updatedAt: new Date(),
    });
  }

  /**
   * Send payment notification (webhook or in-app notification)
   */
  private async sendPaymentNotification(merchantId: string, transaction: Transaction): Promise<void> {
    try {
      // Create in-app notification
      await db.collection('notifications').add({
        merchantId,
        type: 'payment_received',
        title: 'Payment Received!',
        message: `Received ${transaction.amountCrypto} ${transaction.cryptoCurrency} on ${transaction.network}`,
        data: {
          transactionId: transaction.id,
          txHash: transaction.txHash,
          amount: transaction.amountCrypto,
          currency: transaction.cryptoCurrency,
          network: transaction.network,
        },
        read: false,
        createdAt: new Date(),
      });

      console.log(`Payment notification sent to merchant ${merchantId}`);
    } catch (error) {
      console.error('Error sending payment notification:', error);
    }
  }

  /**
   * Get transaction history for a merchant
   */
  async getTransactions(req: Request, res: Response): Promise<void> {
    try {
      const { merchantId } = req.params;
      const { status, network, limit = 50, offset = 0 } = req.query;

      let query = db.collection('transactions')
        .where('merchantId', '==', merchantId)
        .orderBy('observedAt', 'desc');

      if (status) {
        query = query.where('status', '==', status);
      }
      if (network) {
        query = query.where('network', '==', network);
      }

      query = query.limit(parseInt(limit as string))
                   .offset(parseInt(offset as string));

      const snapshot = await query.get();
      
      const transactions: Transaction[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as Transaction));

      res.json({
        success: true,
        transactions,
        count: transactions.length,
      });

    } catch (error) {
      console.error('Error fetching transactions:', error);
      res.status(500).json({ 
        error: 'Failed to fetch transactions',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  /**
   * Get monitoring status for addresses
   */
  async getMonitoringStatus(req: Request, res: Response): Promise<void> {
    try {
      const { merchantId } = req.params;

      const snapshot = await db.collection('monitoredAddresses')
        .where('merchantId', '==', merchantId)
        .orderBy('createdAt', 'desc')
        .limit(20)
        .get();

      const addresses: MonitoredAddress[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as MonitoredAddress));

      res.json({
        success: true,
        addresses,
        count: addresses.length,
      });

    } catch (error) {
      console.error('Error fetching monitoring status:', error);
      res.status(500).json({ 
        error: 'Failed to fetch monitoring status',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}