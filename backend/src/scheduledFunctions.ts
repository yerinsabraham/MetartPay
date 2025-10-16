import { onSchedule } from 'firebase-functions/v2/scheduler';
import { TransactionMonitorController } from './controllers/transactionMonitorController';

const transactionMonitorController = new TransactionMonitorController();

/**
 * Scheduled function to check for new transactions every 2 minutes
 */
export const checkTransactionsScheduled = onSchedule({
  schedule: 'every 2 minutes',
  timeZone: 'UTC',
}, async (event) => {
  console.log('Starting scheduled transaction check...');
  
  try {
    // Create mock request and response objects
    const mockReq = { query: {} } as any;
    const mockRes = {
      json: (data: any) => console.log('Transaction check result:', data),
      status: (code: number) => ({ json: (data: any) => console.log(`Error ${code}:`, data) }),
    } as any;

    await transactionMonitorController.checkTransactions(mockReq, mockRes);
    console.log('Scheduled transaction check completed successfully');
    
  } catch (error) {
    console.error('Scheduled transaction check failed:', error);
    throw error; // Let Firebase Functions handle retry logic
  }
});

/**
 * Scheduled function to clean up expired monitoring addresses daily
 */
export const cleanupExpiredAddresses = onSchedule({
  schedule: 'every 24 hours',
  timeZone: 'UTC',
}, async (event) => {
  console.log('Starting cleanup of expired addresses...');
  
  try {
    const { db } = await import('./index');
    
    const now = new Date();
    const expiredSnapshot = await db.collection('monitoredAddresses')
      .where('expiresAt', '<=', now)
      .where('status', '==', 'active')
      .get();

    if (expiredSnapshot.empty) {
      console.log('No expired addresses to clean up');
      return;
    }

    const batch = db.batch();
    let count = 0;

    expiredSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        updatedAt: new Date(),
      });
      count++;
    });

    await batch.commit();
    console.log(`Cleaned up ${count} expired addresses`);
    
  } catch (error) {
    console.error('Cleanup of expired addresses failed:', error);
    throw error;
  }
});

/**
 * Scheduled function to update confirmation status for pending transactions
 */
export const updatePendingTransactions = onSchedule({
  schedule: 'every 5 minutes',
  timeZone: 'UTC',
}, async (event) => {
  console.log('Updating pending transaction confirmations...');
  
  try {
    const { db } = await import('./index');
    const { BlockchainService } = await import('./services/blockchainService');
    
    const blockchainService = new BlockchainService();
    
    // Get pending and confirming transactions
    const pendingSnapshot = await db.collection('transactions')
      .where('status', 'in', ['pending', 'confirming'])
      .limit(50)
      .get();

    if (pendingSnapshot.empty) {
      console.log('No pending transactions to update');
      return;
    }

    let updated = 0;
    
    for (const doc of pendingSnapshot.docs) {
      try {
        const txData = doc.data();
        const txDetails = await blockchainService.getTransactionDetails(
          txData.network, 
          txData.txHash
        );

        if (!txDetails) continue;

        const config = blockchainService.getNetworkConfig(txData.network);
        if (!config) continue;

        let newStatus = txData.status;
        let confirmedAt;

        if (txDetails.confirmations >= config.requiredConfirmations) {
          newStatus = 'confirmed';
          confirmedAt = new Date();
        } else if (txDetails.confirmations > 0) {
          newStatus = 'confirming';
        }

        if (newStatus !== txData.status) {
          await doc.ref.update({
            confirmations: txDetails.confirmations,
            status: newStatus,
            confirmedAt,
            updatedAt: new Date(),
          });
          updated++;
        }
        
      } catch (error) {
        console.error(`Error updating transaction ${doc.id}:`, error);
      }
    }

    console.log(`Updated ${updated} transaction confirmations`);
    
  } catch (error) {
    console.error('Update pending transactions failed:', error);
    throw error;
  }
});