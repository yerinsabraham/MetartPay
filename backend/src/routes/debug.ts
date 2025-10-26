import { Router } from 'express';
import { db } from '../index';

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