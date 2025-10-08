# MetartPay Setup Guide

## Prerequisites

- Node.js 18+ installed
- Flutter SDK installed  
- Firebase CLI installed
- Git installed

## Phase 0: Setup & Accounts

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Create Firebase Project

```bash
firebase projects:create metartpay --display-name="MetartPay"
```

### 4. Initialize Firebase in Project

```bash
cd backend
firebase init
```

Select:
- Functions (Node.js)
- Firestore Database
- Hosting
- Storage

### 5. Environment Variables Setup

Create `backend/functions/.env` with:

```env
# Firebase
FIREBASE_PROJECT_ID=metartpay

# Crypto Wallets (HD Wallet Seeds - KEEP SECURE!)
ETH_PRIVATE_KEY=your_ethereum_private_key_here
BSC_PRIVATE_KEY=your_bsc_private_key_here  
SOLANA_PRIVATE_KEY=your_solana_private_key_here

# RPC Providers
ETH_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
BSC_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/
SOLANA_RPC_URL=https://api.devnet.solana.com

# Exchange APIs (for manual conversion)
BYBIT_API_KEY=your_bybit_api_key
BYBIT_SECRET=your_bybit_secret

# Banking
BANK_ACCOUNT_NUMBER=3141710052
BANK_NAME=First Bank
BANK_ACCOUNT_NAME=SAIBAKUMO YERINMENE ABRAHAM

# App Config
BASE_URL=https://metartpay.web.app
JWT_SECRET=your_jwt_secret_here
ADMIN_EMAIL=admin@metart.pay
```

### 6. Get Testnet Tokens

#### Ethereum Sepolia Testnet:
1. Get Sepolia ETH: https://sepoliafaucet.com/
2. Get Sepolia USDT: Use Uniswap testnet or faucet
3. Add Sepolia network to MetaMask:
   - RPC: https://sepolia.infura.io/v3/
   - Chain ID: 11155111

#### BSC Testnet:
1. Get tBNB: https://testnet.binance.org/faucet-smart
2. Get testnet USDT/USDC from PancakeSwap testnet

#### Solana Devnet:
1. Get Devnet SOL: `solana airdrop 5 --url devnet`
2. Create test USDC/USDT tokens using Solana CLI

### 7. Wallet Setup Requirements

You'll need approximately:
- **Ethereum Sepolia**: 0.1 ETH (~$0 testnet)
- **BSC Testnet**: 0.1 BNB (~$0 testnet)  
- **Solana Devnet**: 10 SOL (~$0 testnet)
- **Testnet Tokens**: 100 USDT/USDC per chain for testing

### 8. NFC Tags Order

**Recommended NFC Tags:**
- **Type**: NTAG213 (144 bytes, compatible with all phones)
- **Quantity**: 25-50 tags for testing/demo
- **Size**: 25mm diameter stickers
- **Where to buy**: Amazon, AliExpress, or local electronics store
- **Estimated cost**: $0.50-$1.00 per tag

**Amazon Search Terms**: "NTAG213 NFC stickers 25mm"

### 9. Domain Configuration (metart.pay)

Since metart.pay is a premium domain, we'll use Firebase hosting with a subdomain pattern:
- **Primary**: `metartpay.web.app` (free Firebase domain)
- **Custom Domain**: Configure `metart.pay` later in Firebase Hosting
- **Payment URLs**: `https://metartpay.web.app/pay?invoice=xxx`

### 10. Development Environment Check

Run these commands to verify your setup:

```bash
# Check Node.js
node --version  # Should be 18+

# Check Flutter  
flutter doctor

# Check Firebase CLI
firebase --version

# Check Git
git --version
```

## Next Steps

After completing Phase 0 setup:
1. Initialize Firebase project
2. Set up backend development environment
3. Create database schemas
4. Implement crypto wallet infrastructure
5. Build REST API endpoints

## Security Reminders

- Never commit private keys to Git
- Use environment variables for all secrets
- Test with small amounts only
- Keep backup of all wallet seeds
- Use testnet for all initial development