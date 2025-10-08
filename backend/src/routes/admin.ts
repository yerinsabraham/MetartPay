import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { authenticateToken, requireAdmin, AuthenticatedRequest } from '../middleware/auth';

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

export default router;