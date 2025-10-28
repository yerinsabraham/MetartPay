import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { authenticateToken, requireAdmin, AuthenticatedRequest } from '../middleware/auth';
import { db } from '../index';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const router = Router();

const TIER_CONFIG_COLLECTION = 'config_merchantTiers';

// Helper to load tier configs, falling back to defaults in controller when needed
async function listTierConfigs() {
  const snap = await db.collection(TIER_CONFIG_COLLECTION).get();
  if (snap.empty) return [];
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

// Admin routes: use authenticateToken and then requireAdmin where needed. For a small
// set of bootstrap operations we support a secret-based set-admin route.

/**
 * GET /api/admin/merchants/pending
 * List merchants with kycStatus == 'pending'
 */
router.get('/merchants/pending', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const snapshot = await db.collection('merchants').where('kycStatus', '==', 'pending').orderBy('createdAt', 'desc').get();
  const merchants = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  res.json({ success: true, data: merchants });
}));

/**
 * POST /api/admin/merchants/:id/approve
 * Approve merchant KYC. Writes audit log and an in-app notification for the merchant.
 */
router.post('/merchants/:id/approve', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const { reason } = req.body || {};

  const merchantRef = db.collection('merchants').doc(id);
  const snap = await merchantRef.get();
  if (!snap.exists) return res.status(404).json({ success: false, message: 'Merchant not found' });
  const merchant = snap.data() as any;

  await merchantRef.update({ kycStatus: 'verified', updatedAt: new Date() });

  await db.collection('admin_audit_logs').add({
    action: 'approve_kyc',
    merchantId: id,
    reason: reason || '',
    changedBy: req.user?.email || req.user?.uid || 'unknown',
    changedAt: new Date(),
  });

  if (merchant && merchant.userId) {
    const notifRef = db.collection('merchants').doc(merchant.userId).collection('notifications').doc();
    await notifRef.set({
      title: 'KYC Approved',
      body: 'Your merchant application has been approved. You can now create payment requests.',
      type: 'kyc_update',
      isRead: false,
      isCritical: false,
      createdAt: new Date(),
      actionUrl: '/home',
    });
  }

  res.json({ success: true, message: 'Merchant KYC approved' });
}));

/**
 * POST /api/admin/merchants/:id/reject
 * Reject merchant KYC with reason. Writes audit log and in-app notification with reason.
 */
router.post('/merchants/:id/reject', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const { reason } = req.body || {};

  const merchantRef = db.collection('merchants').doc(id);
  const snap = await merchantRef.get();
  if (!snap.exists) return res.status(404).json({ success: false, message: 'Merchant not found' });
  const merchant = snap.data() as any;

  await merchantRef.update({ kycStatus: 'rejected', kycRejectionReason: reason || '', updatedAt: new Date() });

  await db.collection('admin_audit_logs').add({
    action: 'reject_kyc',
    merchantId: id,
    reason: reason || '',
    changedBy: req.user?.email || req.user?.uid || 'unknown',
    changedAt: new Date(),
  });

  if (merchant && merchant.userId) {
    const notifRef = db.collection('merchants').doc(merchant.userId).collection('notifications').doc();
    await notifRef.set({
      title: 'KYC Rejected',
      body: `Your application was rejected. Reason: ${reason || 'Not specified'}`,
      type: 'kyc_update',
      isRead: false,
      isCritical: true,
      createdAt: new Date(),
      actionUrl: '/setup',
    });
  }

  res.json({ success: true, message: 'Merchant KYC rejected' });
}));

/**
 * POST /api/admin/set-admin - set a user as admin by email
 * Supports bootstrap via ADMIN_BOOTSTRAP_SECRET env var OR must be called by an existing admin.
 */
router.post('/set-admin', asyncHandler(async (req: Request, res: Response) => {
  try {
    const { email, secret } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email required' });

    const configured = process.env.ADMIN_BOOTSTRAP_SECRET || '';
    const viaBootstrap = configured && secret && secret === configured;

    // If not bootstrap, require admin auth
    if (!viaBootstrap) {
      return res.status(403).json({ error: 'Bootstrap secret required to call this endpoint without admin auth' });
    }

    const auth = getAuth();
    const user = await auth.getUserByEmail(email.toLowerCase());
    const uid = user.uid;

    const existingClaims = user.customClaims || {};
    const newClaims = Object.assign({}, existingClaims, { admin: true });
    await auth.setCustomUserClaims(uid, newClaims as any);

    await db.collection('users').doc(uid).set({ isAdmin: true, updatedAt: new Date() }, { merge: true });

    await db.collection('admin_audit_logs').add({
      action: 'setAdminViaApi',
      targetEmail: email.toLowerCase(),
      targetUid: uid,
      changedBy: 'bootstrap',
      changedAt: new Date(),
      viaBootstrap: true,
    });

    // Mark bootstrap used
    await db.collection('admin_bootstrap').doc('metadata').set({ used: true, usedByEmail: email.toLowerCase(), usedAt: new Date() }, { merge: true });

    return res.json({ success: true, uid });
  } catch (err) {
    console.error('set-admin error', err);
    return res.status(500).json({ error: 'internal' });
  }
}));


  /**
   * GET /api/admin/tiers
   * List tier configurations available
   */
  router.get('/tiers', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const tiers = await listTierConfigs();
    res.json({ success: true, tiers });
  }));


  /**
   * POST /api/admin/tiers
   * Create or update a tier config. Body must contain id and payload.
   */
  router.post('/tiers', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const body = req.body || {};
    const { id } = body;
    if (!id) return res.status(400).json({ success: false, error: 'id required' });

    await db.collection(TIER_CONFIG_COLLECTION).doc(id).set(body, { merge: true });

    await db.collection('admin_audit_logs').add({
      action: 'upsert_tier_config',
      tierId: id,
      changedBy: req.user?.email || req.user?.uid || 'unknown',
      changedAt: new Date(),
      data: body,
    });

    res.json({ success: true, id });
  }));


  /**
   * POST /api/admin/merchants/:id/upgrade - merchant requests an upgrade (merchant-authenticated)
   */
  router.post('/merchants/:id/upgrade', authenticateToken, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const { requestedTier, notes } = req.body || {};
    if (!requestedTier) return res.status(400).json({ success: false, error: 'requestedTier required' });

    // Ensure merchant exists and user owns it
    const mRef = db.collection('merchants').doc(id);
    const snap = await mRef.get();
    if (!snap.exists) return res.status(404).json({ success: false, error: 'merchant not found' });
    const merchant = snap.data() as any;
    if (merchant.userId !== req.user?.uid) return res.status(403).json({ success: false, error: 'forbidden' });

    const reqDoc = { requestedTier, notes: notes || '', requestedAt: new Date(), requestedBy: req.user?.uid };
    await mRef.collection('tierUpgradeRequests').doc().set(reqDoc);

    await mRef.update({ upgradeRequested: reqDoc, updatedAt: new Date() });

    await db.collection('admin_audit_logs').add({
      action: 'merchant_requested_upgrade',
      merchantId: id,
      requestedTier,
      requestedBy: req.user?.uid,
      requestedAt: new Date(),
    });

    res.json({ success: true, message: 'Upgrade request submitted' });
  }));


  /**
   * POST /api/admin/merchants/:id/approve-upgrade
   * Admin approves merchant upgrade to new tier. Body: { newTier, reason }
   */
  router.post('/merchants/:id/approve-upgrade', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const { newTier, reason } = req.body || {};
    if (!newTier) return res.status(400).json({ success: false, error: 'newTier required' });

    const mRef = db.collection('merchants').doc(id);
    const snap = await mRef.get();
    if (!snap.exists) return res.status(404).json({ success: false, error: 'merchant not found' });
    const merchant = snap.data() as any;

    const prev = merchant.merchantTier || null;
    await mRef.update({ merchantTier: newTier, updatedAt: new Date() });

    // record tier history
    await mRef.collection('tierHistory').add({
      prevTier: prev,
      newTier,
      changedBy: req.user?.uid || req.user?.email || 'admin',
      reason: reason || '',
      changedAt: new Date(),
    });

    await db.collection('admin_audit_logs').add({
      action: 'approve_tier_upgrade',
      merchantId: id,
      prevTier: prev,
      newTier,
      changedBy: req.user?.email || req.user?.uid || 'unknown',
      changedAt: new Date(),
      reason: reason || ''
    });

    if (merchant && merchant.userId) {
      const notifRef = db.collection('merchants').doc(merchant.userId).collection('notifications').doc();
      await notifRef.set({
        title: 'Tier Upgrade Approved',
        body: `Your account has been upgraded to ${newTier}`,
        type: 'tier_update',
        isRead: false,
        createdAt: new Date(),
        actionUrl: '/profile',
      });
    }

    res.json({ success: true, message: 'Tier upgrade approved' });
  }));


  /**
   * POST /api/admin/merchants/:id/reject-upgrade
   */
  router.post('/merchants/:id/reject-upgrade', authenticateToken, requireAdmin, asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const { reason } = req.body || {};
    const mRef = db.collection('merchants').doc(id);
    const snap = await mRef.get();
    if (!snap.exists) return res.status(404).json({ success: false, error: 'merchant not found' });
    const merchant = snap.data() as any;

    await mRef.update({ upgradeRequested: null, updatedAt: new Date() });

    await db.collection('admin_audit_logs').add({
      action: 'reject_tier_upgrade',
      merchantId: id,
      changedBy: req.user?.email || req.user?.uid || 'unknown',
      changedAt: new Date(),
      reason: reason || ''
    });

    if (merchant && merchant.userId) {
      const notifRef = db.collection('merchants').doc(merchant.userId).collection('notifications').doc();
      await notifRef.set({
        title: 'Tier Upgrade Rejected',
        body: `Your tier upgrade request was rejected. Reason: ${reason || 'Not specified'}`,
        type: 'tier_update',
        isRead: false,
        isCritical: true,
        createdAt: new Date(),
        actionUrl: '/profile',
      });
    }

    res.json({ success: true, message: 'Tier upgrade rejected' });
  }));

export default router;
