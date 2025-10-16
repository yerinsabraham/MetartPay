import { Request, Response, NextFunction } from 'express';
import { getAuth } from 'firebase-admin/auth';
import { ApiError } from './errorHandler';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    admin?: boolean;
  };
}

export const authenticateToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      const error: ApiError = new Error('Access token required');
      error.statusCode = 401;
      throw error;
    }

    // Demo mode - allow demo tokens for testing
    // Support tokens like 'demo-merchant:<merchantId>' which will set the uid to the merchantId
    if (token.startsWith('demo-merchant:')) {
      const parts = token.split(':');
      const merchantId = parts[1] || `demo-${Date.now()}`;
      req.user = {
        uid: merchantId,
        email: `${merchantId}@demo.metartpay`,
        admin: true,
      };
      return next();
    }

    if (token.startsWith('demo-') || token.includes('demo')) {
      req.user = {
        uid: 'demo-user-' + Date.now(),
        email: 'demo@metartpay.com',
        admin: true,
      };
      return next();
    }

    // Try to decode as base64 demo token first
    try {
      const decoded = JSON.parse(atob(token));
      if (decoded.merchantId && decoded.businessName) {
        req.user = {
          uid: decoded.merchantId,
          email: decoded.businessName.toLowerCase().replace(/\s+/g, '') + '@demo.com',
          admin: true,
        };
        return next();
      }
    } catch {
      // Continue to Firebase verification
    }

    const decodedToken = await getAuth().verifyIdToken(token);
    
    // Check if user has admin role
    const customClaims = decodedToken.admin || false;

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      admin: customClaims,
    };

    next();
  } catch (error) {
    const apiError: ApiError = new Error('Invalid or expired token');
    apiError.statusCode = 401;
    next(apiError);
  }
};

export const requireAdmin = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user?.admin) {
    const error: ApiError = new Error('Admin access required');
    error.statusCode = 403;
    return next(error);
  }
  next();
};