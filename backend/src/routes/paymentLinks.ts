import { Router } from 'express';
import { PaymentLinkController } from '../controllers/paymentLinkController';
import { authenticateToken } from '../middleware/auth';

const router = Router();
const paymentLinkController = new PaymentLinkController();

// Protected routes (require authentication)
router.post('/:merchantId', authenticateToken, paymentLinkController.createPaymentLink.bind(paymentLinkController));
router.get('/merchant/:merchantId', authenticateToken, paymentLinkController.getPaymentLinks.bind(paymentLinkController));
router.put('/:linkId', authenticateToken, paymentLinkController.updatePaymentLink.bind(paymentLinkController));
router.delete('/:linkId', authenticateToken, paymentLinkController.deletePaymentLink.bind(paymentLinkController));

// Public routes (no auth required for customers)
router.get('/:linkId', paymentLinkController.getPaymentLink.bind(paymentLinkController));
router.get('/:linkId/qr', paymentLinkController.generateQRCode.bind(paymentLinkController));

export { router as paymentLinkRoutes };