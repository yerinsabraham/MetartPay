const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.static(__dirname));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'MetartPay Customer Portal'
    });
});

// API proxy endpoints for testing (optional)
app.post('/api/test-payment', (req, res) => {
    const { amount, description, businessName } = req.body;
    
    // Simulate payment link creation
    const mockPaymentLink = {
        id: 'test-' + Date.now(),
        title: description,
        amount: amount,
        businessName: businessName,
        status: 'active',
        createdAt: new Date(),
        cryptoOptions: [
            {
                network: 'ETH',
                token: 'USDT',
                amount: (amount / 1645).toFixed(6),
                address: '0x' + Math.random().toString(16).substr(2, 40)
            },
            {
                network: 'BSC',
                token: 'USDT',
                amount: (amount / 1645).toFixed(6),
                address: '0x' + Math.random().toString(16).substr(2, 40)
            }
        ]
    };
    
    res.json({ success: true, paymentLink: mockPaymentLink });
});

app.listen(PORT, () => {
    console.log(`🚀 MetartPay Customer Portal running on http://localhost:${PORT}`);
    console.log(`📱 Access the payment interface at: http://localhost:${PORT}`);
});