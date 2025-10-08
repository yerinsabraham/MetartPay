import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();

// POST /api/auth/login - Login with Firebase Auth
router.post('/login', asyncHandler(async (req: Request, res: Response) => {
  // Firebase Auth handles authentication on the client side
  // This endpoint can be used for additional login logic if needed
  res.status(200).json({
    success: true,
    message: 'Login successful',
  });
}));

// POST /api/auth/register - Register new user
router.post('/register', asyncHandler(async (req: Request, res: Response) => {
  // Firebase Auth handles registration on the client side
  // This endpoint can be used for additional registration logic if needed
  res.status(201).json({
    success: true,
    message: 'Registration successful',
  });
}));

export default router;