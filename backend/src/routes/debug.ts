import { Router } from 'express';
import { db } from '../index';
import { verifyEvmTransfer } from '../services/ethereumService';

// NOTE: This file exposes dev-only endpoints and must be enabled by
// setting process.env.ENABLE_DEV_DEBUG = 'true'. These routes are NOT
// intended for production use.

const router = Router();

// Dev-only route guarded by env flag
router.get('/recent-payment-payloads', async (req, res) => {
  try {
    if (process.env.ENABLE_DEV_DEBUG !== 'true') return res.status(403).json({ error: 'disabled' });

    const snapshot = await db.collection('paymentDebugLogs').orderBy('createdAt', 'desc').limit(50).get();
    const logs = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ success: true, logs });
  } catch (e) {
    console.error('Failed to fetch recent payment payloads:', e);
    res.status(500).json({ error: 'internal' });
  }
});

export { router as debugRoutes };

// Dev-only unauthenticated reverify endpoint
router.post('/dev/admin/reverify/:txHash', async (req, res) => {
  if (process.env.ENABLE_DEV_DEBUG !== 'true') return res.status(403).json({ error: 'disabled' });
  const { txHash } = req.params;
  if (!txHash) return res.status(400).json({ error: 'txHash required' });

  try {
    const network = req.body?.network || req.query?.network || 'sepolia';
    const token = req.body?.tokenContractAddress || req.query?.tokenContractAddress;
    const expectedValueWei = req.body?.expectedValueWei || req.query?.expectedValueWei;

    const result = await verifyEvmTransfer(txHash, req.body?.expectedToAddress || req.query?.expectedToAddress || '', expectedValueWei, network, token);

    // Optionally update transaction record in Firestore if present
    try {
      const txs = await db.collection('transactions').where('txHash', '==', txHash).limit(1).get();
      if (!txs.empty) {
        const doc = txs.docs[0];
        await doc.ref.set({ lastReverify: new Date(), lastReverifyResult: result }, { merge: true });
      }
    } catch (e) {
      console.warn('Failed to update transaction record during dev reverify', e);
    }

    return res.json({ success: true, result });
  } catch (err: any) {
    console.error('Dev reverify failed', err);
    return res.status(500).json({ error: err?.message || 'internal' });
  }
});

// Dev-only: Inspect in-memory store (if enabled). Useful when ENABLE_DEV_IN_MEMORY
// is true and you want to confirm which synthetic transactions exist in the
// running process. Only available when ENABLE_DEV_DEBUG='true'.
router.get('/dev/inmemory/dump', async (req, res) => {
  if (process.env.ENABLE_DEV_DEBUG !== 'true') return res.status(403).json({ error: 'disabled' });
  if (process.env.ENABLE_DEV_IN_MEMORY !== 'true') return res.status(400).json({ error: 'in-memory store not enabled' });
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const inm = require('../dev/inMemoryStore').default;
    const dump = await inm._dump();
    return res.json({ success: true, dump });
  } catch (e) {
    console.error('Failed to dump in-memory store', e);
    return res.status(500).json({ success: false, error: 'failed to dump in-memory store' });
  }
});