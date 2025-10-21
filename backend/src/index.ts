import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

// Import route handlers
import authRoutes from './routes/auth';
import merchantRoutes from './routes/merchants';
import invoiceRoutes from './routes/invoices';
import paymentRoutes from './routes/payments';
import adminRoutes from './routes/admin';
import webhookRoutes from './routes/webhooks';
import walletRoutes from './routes/wallets';
import { paymentLinkRoutes } from './routes/paymentLinks';
import { transactionMonitorRoutes } from './routes/transactionMonitor';
import { debugRoutes } from './routes/debug';
import { errorHandler, notFound } from './middleware/errorHandler';

// Load environment variables
dotenv.config();

// If running as a local standalone server, prefer the emulator for Firestore
// and Auth so the Admin SDK doesn't attempt to load Google Application
// Default Credentials. This makes LOCAL_SERVER mode easy to run without
// requiring a service account JSON file.
if (process.env.LOCAL_SERVER === 'true' && process.env.NODE_ENV !== 'production') {
    process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
    // Optionally set the Auth emulator host if present locally
    process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
    console.log('LOCAL_SERVER mode detected; using emulator hosts:', {
        FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
        FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
    });
}

// Initialize Firebase Admin AFTER we may have set emulator env vars
initializeApp();
export const db = getFirestore();

// Set global options for Firebase Functions
setGlobalOptions({
  maxInstances: 10,
  region: 'us-central1',
});

// Create Express app
const app = express();

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://metartpay.web.app', 'https://metartpay-bac2f.web.app']
    : true,
  credentials: true,
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// API routes
// Dev helper: rewrite several common function/emulator wrapper prefixes so
// local clients don't need to special-case paths. This middleware is active
// in any non-production environment.
if (process.env.NODE_ENV !== 'production') {
    app.use((req, res, next) => {
        try {
            const original = (req as any).url || req.url || '';
            let rewritten = original;

            // /functions/... -> /...
            if (/^\/functions/.test(rewritten)) {
                rewritten = rewritten.replace(/^\/functions/, '') || '/';
            }

            // /<project>/(us-central1|europe-west1)/api/... -> /api/...
            // Example: /metartpay-bac2f/us-central1/api/payments -> /api/payments
            rewritten = rewritten.replace(/^\/[^\/]+\/(us-central1|europe-west1)\/api/, '/api');

            if (rewritten !== original) {
                (req as any).url = rewritten;
                console.log('Rewrote request', original, '->', rewritten);
            }
        } catch (err) {
            console.warn('Failed to rewrite function wrapper path', err);
        }
        next();
    });
}
app.use('/api/auth', authRoutes);
app.use('/api/merchants', merchantRoutes);
app.use('/api/invoices', invoiceRoutes);
app.use('/api/payments', paymentRoutes);
// Also mount without the '/api' prefix so the Firebase Functions onRequest wrapper
// (which exposes this app at the path /.../api) will correctly route requests that
// arrive at '/payments/...' when the function base path already includes 'api'.
app.use('/payments', paymentRoutes);

// Bootstrap endpoint to set initial admin by email using ADMIN_BOOTSTRAP_SECRET
app.post('/api/admin/set-admin', async (req, res) => {
    try {
        const { email, secret } = req.body || {};
        if (!email) return res.status(400).json({ error: 'email required' });

        const configured = process.env.ADMIN_BOOTSTRAP_SECRET || '';
        if (!configured || configured !== secret) {
            return res.status(403).json({ error: 'invalid or expired token' });
        }

        // Ensure bootstrap not already used
        const metaRef = db.collection('admin_bootstrap').doc('metadata');
        const metaDoc = await metaRef.get();
        if (metaDoc.exists && metaDoc.data()?.used === true) {
            return res.status(403).json({ error: 'bootstrap secret already used' });
        }

        const auth = (await import('firebase-admin')).auth();
        const user = await auth.getUserByEmail(email.toLowerCase());
        const uid = user.uid;

        const existingClaims = user.customClaims || {};
        const newClaims = Object.assign({}, existingClaims, { admin: true });
        await auth.setCustomUserClaims(uid, newClaims as any);

        await db.collection('users').doc(uid).set({ isAdmin: true, updatedAt: new Date() }, { merge: true });

        await db.collection('admin_audit_logs').add({
            action: 'setAdminViaBootstrap',
            targetEmail: email.toLowerCase(),
            targetUid: uid,
            changedBy: 'bootstrap',
            changedAt: new Date(),
            viaBootstrap: true,
        });

        await metaRef.set({ used: true, usedByEmail: email.toLowerCase(), usedAt: new Date() }, { merge: true });

        return res.json({ success: true, uid });
    } catch (err) {
        console.error('bootstrap set-admin error', err);
        return res.status(500).json({ error: 'internal' });
    }
});

// verify-admin endpoint removed

// Mount protected admin routes after bootstrap endpoint so the bootstrap path is
// reachable without admin auth.
app.use('/api/admin', adminRoutes);
app.use('/api/webhooks', webhookRoutes);
app.use('/api/wallets', walletRoutes);
app.use('/api/payment-links', paymentLinkRoutes);
app.use('/api/transactions', transactionMonitorRoutes);
if (process.env.ENABLE_DEV_DEBUG === 'true') {
    app.use('/api/debug', debugRoutes);
}

// Public endpoint: Get transaction by id (used by mobile polling fallback).
// If ENABLE_DEV_IN_MEMORY=true, consult the in-memory store first.
app.get('/transactions/:id', async (req, res) => {
    try {
        const id = req.params.id;
        if (!id) return res.status(400).json({ success: false, error: 'id required' });

        if (process.env.ENABLE_DEV_IN_MEMORY === 'true') {
            try {
                // eslint-disable-next-line @typescript-eslint/no-var-requires
                const inm = require('./dev/inMemoryStore').default;
                // Primary: look up by the transaction document id
                const docById = await inm.getTransactionById(id);
                if (docById) return res.json({ success: true, transaction: docById.data });

                // Fallback: sometimes callers provide a txHash instead of the internal id;
                // try searching by txHash to be resilient during dev flows.
                try {
                    const found = await inm.findTransactionByTxHash(id);
                    if (found) {
                        console.log('GET /transactions: falling back to txHash lookup for', id, '->', found.id);
                        return res.json({ success: true, transaction: found.data });
                    }
                } catch (inner) {
                    console.warn('in-memory findTransactionByTxHash failed', inner);
                }
            } catch (e) {
                console.warn('in-memory getTransaction failed', e);
            }
        }

        // Fall back to Firestore
        const snapshot = await db.collection('transactions').doc(id).get();
        if (!snapshot.exists) return res.status(404).json({ success: false, error: 'not found' });
        return res.json({ success: true, transaction: { id: snapshot.id, ...snapshot.data() } });
    } catch (err) {
        console.error('GET /transactions/:id failed', err);
        return res.status(500).json({ success: false, error: 'internal' });
    }
});

// Public payment page routes (no /api prefix)
app.get('/pay/:linkId', async (req, res) => {
  try {
    const { linkId } = req.params;
    const { network, token } = req.query;
    
    // Get payment link from database
    const paymentLinkDoc = await db.collection('paymentLinks').doc(linkId).get();
    
    if (!paymentLinkDoc.exists) {
      return res.status(404).send('Payment link not found');
    }

    const paymentLink = paymentLinkDoc.data();
    
    // Check if link is expired
    if (paymentLink!.expiresAt && new Date() > paymentLink!.expiresAt.toDate()) {
      return res.status(410).send('Payment link has expired');
    }

    if (paymentLink!.status !== 'active') {
      return res.status(410).send('Payment link is not active');
    }
    
    // Get merchant details
    const merchantDoc = await db.collection('merchants').doc(paymentLink!.merchantId).get();
    const merchant = merchantDoc.data();

    // Render payment link page
    const paymentPageHtml = generatePaymentLinkPageHtml(paymentLink, merchant, network as string, token as string);
    res.send(paymentPageHtml);

  } catch (error) {
    console.error('Error serving payment link page:', error);
    res.status(500).send('Internal server error');
  }
});

app.get('/pay', async (req, res) => {
  try {
    const { invoice: invoiceId } = req.query;
    
    if (!invoiceId) {
      return res.status(400).send('Invoice ID required');
    }

    // Get invoice from database
    const invoiceDoc = await db.collection('invoices').doc(invoiceId as string).get();
    
    if (!invoiceDoc.exists) {
      return res.status(404).send('Invoice not found');
    }

    const invoice = invoiceDoc.data();
    
    // Get merchant details
    const merchantDoc = await db.collection('merchants').doc(invoice!.merchantId).get();
    const merchant = merchantDoc.data();

    // Render payment page (we'll create this template)
    const paymentPageHtml = generatePaymentPageHtml(invoice, merchant);
    res.send(paymentPageHtml);

  } catch (error) {
    console.error('Error serving payment page:', error);
    res.status(500).send('Internal server error');
  }
});

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Export the Firebase Function (always exported for functions deployments)
export const api = onRequest(app);

// Export scheduled functions
export * from './scheduledFunctions';

// If running in 'LOCAL_SERVER' mode, also start the Express app directly so
// developers can run the backend without the Firebase emulator.
if (process.env.LOCAL_SERVER === 'true') {
    const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 5001;
    app.listen(port, () => console.log(`Local Express API listening on http://localhost:${port}`));
}

// Helper function to generate payment link page HTML
function generatePaymentLinkPageHtml(paymentLink: any, merchant: any, selectedNetwork?: string, selectedToken?: string): string {
  // Find the selected crypto option or use the first one
  const cryptoOption = paymentLink.cryptoOptions.find((opt: any) => 
    opt.network === selectedNetwork && opt.token === selectedToken
  ) || paymentLink.cryptoOptions[0];

  const networkName = cryptoOption.network === 'ETH' ? 'Ethereum' : 
                     cryptoOption.network === 'BSC' ? 'Binance Smart Chain' : 
                     cryptoOption.network === 'MATIC' ? 'Polygon' : cryptoOption.network;

  return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pay ${merchant?.businessName || 'Business'} - MetartPay</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 420px; margin: 20px auto; padding: 20px; }
        .card { background: white; border-radius: 16px; padding: 32px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); }
        .merchant-name { font-size: 28px; font-weight: bold; color: #2d3748; margin-bottom: 8px; text-align: center; }
        .payment-title { font-size: 18px; color: #718096; text-align: center; margin-bottom: 24px; }
        .amount-section { text-align: center; margin: 24px 0; padding: 24px; background: #f8fafc; border-radius: 12px; }
        .naira-amount { font-size: 36px; font-weight: bold; color: #38a169; }
        .crypto-amount { font-size: 20px; color: #4a5568; margin-top: 8px; }
        .network-selector { margin: 20px 0; }
        .network-options { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
        .network-btn { padding: 8px 16px; border: 2px solid #e2e8f0; border-radius: 8px; background: white; cursor: pointer; font-size: 14px; }
        .network-btn.active { border-color: #4299e1; background: #ebf8ff; color: #2b6cb0; }
        .qr-container { text-align: center; margin: 24px 0; padding: 24px; background: #f7fafc; border-radius: 12px; }
        .address-section { margin: 20px 0; }
        .address { font-family: 'SF Mono', Monaco, monospace; font-size: 12px; word-break: break-all; background: #edf2f7; padding: 16px; border-radius: 8px; margin: 12px 0; border: 1px solid #e2e8f0; }
        .copy-btn { background: #4299e1; color: white; border: none; padding: 12px 24px; border-radius: 8px; cursor: pointer; font-weight: 600; width: 100%; margin-top: 8px; }
        .copy-btn:hover { background: #3182ce; }
        .network-info { background: linear-gradient(135deg, #e6fffa, #b2f5ea); padding: 16px; border-radius: 8px; margin: 16px 0; border: 1px solid #81e6d9; }
        .instructions { background: #fef5e7; border: 1px solid #f6e05e; padding: 16px; border-radius: 8px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 32px; padding-top: 24px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #a0aec0; }
        .logo { width: 24px; height: 24px; display: inline-block; margin-right: 8px; vertical-align: middle; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="merchant-name">${merchant?.businessName || 'Business'}</div>
            <div class="payment-title">${paymentLink.title}</div>
            ${paymentLink.description ? `<div style="text-align: center; color: #718096; margin-bottom: 20px;">${paymentLink.description}</div>` : ''}
            
            <div class="amount-section">
                <div class="naira-amount">₦${Number(paymentLink.amount).toLocaleString()}</div>
                <div class="crypto-amount">${cryptoOption.amount} ${cryptoOption.token}</div>
            </div>

            ${paymentLink.cryptoOptions.length > 1 ? `
            <div class="network-selector">
                <strong>Choose Payment Method:</strong>
                <div class="network-options">
                    ${paymentLink.cryptoOptions.map((opt: any) => `
                        <button class="network-btn ${opt.network === cryptoOption.network && opt.token === cryptoOption.token ? 'active' : ''}" 
                                onclick="selectNetwork('${opt.network}', '${opt.token}')">
                            ${opt.network} ${opt.token}
                        </button>
                    `).join('')}
                </div>
            </div>
            ` : ''}
            
            <div class="network-info">
                <strong>Network:</strong> ${networkName}<br>
                <strong>Token:</strong> ${cryptoOption.token}<br>
                <strong>Amount:</strong> ${cryptoOption.amount} ${cryptoOption.token}
            </div>
            
            <div class="qr-container">
                <div id="qrcode" style="display: inline-block;"></div>
                <div style="margin-top: 12px; font-size: 14px; color: #718096;">
                    Scan with your ${networkName} wallet
                </div>
            </div>
            
            <div class="address-section">
                <strong>Or send to this address:</strong>
                <div class="address" id="address">${cryptoOption.address}</div>
                <button class="copy-btn" onclick="copyAddress()">📋 Copy Address</button>
            </div>

            <div class="instructions">
                <strong>⚠️ Important:</strong><br>
                • Send exactly <strong>${cryptoOption.amount} ${cryptoOption.token}</strong><br>
                • Use ${networkName} network only<br>
                • Payment will be confirmed automatically
            </div>
            
            <div class="footer">
                <svg class="logo" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
                Powered by MetartPay
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
    <script>
        const currentCryptoOption = ${JSON.stringify(cryptoOption)};
        
        function generateQR() {
            const address = currentCryptoOption.address;
            const amount = currentCryptoOption.amount;
            const token = currentCryptoOption.token;
            const network = currentCryptoOption.network;
            
            let qrData;
            if (network === 'SOL') {
                qrData = \`solana:\${address}?amount=\${amount}&token=\${token}\`;
            } else {
                qrData = \`ethereum:\${address}?value=\${amount}&token=\${token}\`;
            }
            
            QRCode.toCanvas(document.getElementById('qrcode'), qrData, {
                width: 200,
                margin: 2,
                color: {
                    dark: '#000000',
                    light: '#ffffff'
                }
            });
        }
        
        function copyAddress() {
            navigator.clipboard.writeText(currentCryptoOption.address).then(() => {
                const btn = document.querySelector('.copy-btn');
                const originalText = btn.textContent;
                btn.textContent = '✅ Copied!';
                btn.style.background = '#38a169';
                setTimeout(() => {
                    btn.textContent = originalText;
                    btn.style.background = '#4299e1';
                }, 2000);
            }).catch(() => {
                alert('Address: ' + currentCryptoOption.address);
            });
        }

        function selectNetwork(network, token) {
            const url = new URL(window.location);
            url.searchParams.set('network', network);
            url.searchParams.set('token', token);
            window.location.href = url.toString();
        }
        
        // Generate initial QR code
        generateQR();
        
        // Check for transactions (placeholder - we'll implement this in the monitoring system)
        console.log('Monitoring for transactions to:', currentCryptoOption.address);
    </script>
</body>
</html>`;
}

// Helper function to generate payment page HTML
function generatePaymentPageHtml(invoice: any, merchant: any): string {
  return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pay ${merchant?.businessName || 'Merchant'} - MetartPay</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f7fa; }
        .container { max-width: 400px; margin: 50px auto; padding: 20px; }
        .card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.1); }
        .merchant-name { font-size: 24px; font-weight: bold; color: #2d3748; margin-bottom: 8px; }
        .amount { font-size: 32px; font-weight: bold; color: #38a169; margin: 16px 0; }
        .crypto-amount { font-size: 18px; color: #718096; margin-bottom: 24px; }
        .qr-container { text-align: center; margin: 24px 0; padding: 20px; background: #f7fafc; border-radius: 8px; }
        .address { font-family: monospace; font-size: 12px; word-break: break-all; background: #edf2f7; padding: 12px; border-radius: 6px; margin: 16px 0; }
        .copy-btn { background: #4299e1; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; }
        .status { text-align: center; margin-top: 24px; padding: 12px; border-radius: 6px; }
        .pending { background: #fef5e7; color: #d69e2e; }
        .paid { background: #f0fff4; color: #38a169; }
        .network-info { background: #e6fffa; padding: 12px; border-radius: 6px; margin: 16px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="merchant-name">${merchant?.businessName || 'Merchant'}</div>
            <div class="amount">₦${Number(invoice.amountNaira).toLocaleString()}</div>
            <div class="crypto-amount">${invoice.amountCrypto} ${invoice.cryptoSymbol}</div>
            
            <div class="network-info">
                <strong>Network:</strong> ${invoice.chain}<br>
                <strong>Token:</strong> ${invoice.cryptoSymbol}
            </div>
            
            <div class="qr-container">
                <div id="qrcode" style="display: inline-block;"></div>
                <div style="margin-top: 12px; font-size: 14px; color: #718096;">
                    Scan QR code with your crypto wallet
                </div>
            </div>
            
            <div>
                <strong>Send to this address:</strong>
                <div class="address" id="address">${invoice.receivingAddress}</div>
                <button class="copy-btn" onclick="copyAddress()">Copy Address</button>
            </div>
            
            <div class="status ${invoice.status}">
                Status: ${invoice.status.toUpperCase()}
            </div>
            
            <div style="text-align: center; margin-top: 24px; font-size: 12px; color: #a0aec0;">
                Powered by MetartPay
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
    <script>
        // Generate QR code
        const address = '${invoice.receivingAddress}';
        const amount = '${invoice.amountCrypto}';
        const token = '${invoice.cryptoSymbol}';
        
        let qrData;
        if ('${invoice.chain}' === 'SOL') {
            qrData = \`solana:\${address}?amount=\${amount}&token=\${token}\`;
        } else {
            qrData = \`ethereum:\${address}?value=\${amount}&token=\${token}\`;
        }
        
        QRCode.toCanvas(document.getElementById('qrcode'), qrData, {
            width: 200,
            margin: 2,
            color: {
                dark: '#000000',
                light: '#ffffff'
            }
        });
        
        function copyAddress() {
            navigator.clipboard.writeText(address).then(() => {
                alert('Address copied to clipboard!');
            });
        }
        
        // Check payment status every 10 seconds
        setInterval(async () => {
            try {
                const response = await fetch(\`/api/invoices/\${invoice.id}\`);
                const data = await response.json();
                
                if (data.status === 'paid') {
                    location.reload();
                }
            } catch (error) {
                console.log('Error checking status:', error);
            }
        }, 10000);
    </script>
</body>
</html>`;
}