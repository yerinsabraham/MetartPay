import { Router } from 'express';
import { TransactionMonitorController } from '../controllers/transactionMonitorController';
import { authenticateToken } from '../middleware/auth';

const router = Router();
const transactionMonitorController = new TransactionMonitorController();

// Protected routes (require authentication)
router.post('/start', authenticateToken, transactionMonitorController.startMonitoring.bind(transactionMonitorController));
router.get('/transactions/:merchantId', authenticateToken, transactionMonitorController.getTransactions.bind(transactionMonitorController));
router.get('/addresses/:merchantId', authenticateToken, transactionMonitorController.getMonitoringStatus.bind(transactionMonitorController));

// Internal route for scheduled function (should be secured with API key in production)
router.post('/check', transactionMonitorController.checkTransactions.bind(transactionMonitorController));

export { router as transactionMonitorRoutes };