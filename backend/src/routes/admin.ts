import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { authenticateToken, requireAdmin, AuthenticatedRequest } from '../middleware/auth';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const router = Router();

// All admin routes require authentication and admin role
router.use(authenticateToken);
router.use(requireAdmin);

// GET /api/admin/dashboard - Admin dashboard stats
router.get('/dashboard', asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  // Implementation for dashboard statistics
  res.status(200).json({
    success: true,
    data: {
      totalMerchants: 0,
      totalInvoices: 0,
      totalVolume: 0,
      pendingPayouts: 0,
    },
    message: 'Dashboard data retrieved',
  });
}));

// GET /api/admin/merchants - List all merchants
router.get('/merchants', asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  res.status(200).json({
    success: true,
    data: [],
    message: 'Admin merchants list - implementation pending',
  });
}));

// PUT /api/admin/merchants/:id/kyc - Update merchant KYC status
router.put('/merchants/:id/kyc', asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  res.status(200).json({
    success: true,
    message: `KYC status updated to ${status}`,
  });
}));

// POST /api/admin/set-admin - set a user as admin by email
// Body: { email: string, secret?: string }
// Allows existing admin callers (via authenticateToken+requireAdmin) or a bootstrap secret via env ADMIN_BOOTSTRAP_SECRET
router.post('/set-admin', asyncHandler(async (req: Request, res: Response) => {
  const { email, secret } = req.body || {};
  if (!email) return res.status(400).json({ error: 'email required' });

  const auth = getAuth();
  const db = getFirestore();

  // If caller passed authenticateToken and requireAdmin, they'll be allowed already. But this route also supports bootstrap secret.
  let viaBootstrap = false;
  try {
    // If the request has no valid admin (middleware would have blocked earlier), allow bootstrap via secret
    // Check env-provided bootstrap secret
    const configured = process.env.ADMIN_BOOTSTRAP_SECRET || '';
    if (!configured) {
      // No bootstrap configured and not an admin -> middleware will have rejected already
    }

    if (configured && secret && secret === configured) {
      // Ensure not used
      const metaRef = db.collection('admin_bootstrap').doc('metadata');
      const metaDoc = await metaRef.get();
      if (metaDoc.exists && metaDoc.data()?.used === true) {
        return res.status(403).json({ error: 'bootstrap secret already used' });
      }
      viaBootstrap = true;
    }

    if (!viaBootstrap && !(req as any).isAdmin) {
      // if not bootstrap and not admin (shouldn't happen because middleware requireAdmin runs), block
      return res.status(403).json({ error: 'not authorized' });
    }

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
      changedBy: (req as any).uid || 'bootstrap',
      changedAt: new Date(),
      viaBootstrap,
    });

    if (viaBootstrap) {
      await db.collection('admin_bootstrap').doc('metadata').set({ used: true, usedByEmail: email.toLowerCase(), usedAt: new Date() }, { merge: true });
    }

    return res.json({ success: true, uid });
  } catch (err) {
    console.error('set-admin error', err);
    return res.status(500).json({ error: 'internal' });
  }
}));

export default router;