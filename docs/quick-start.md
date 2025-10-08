# Quick Start Commands for MetartPay

## Initial Setup (Run Once)
```bash
# 1. Accept Google Cloud Terms of Service
# Visit: https://console.cloud.google.com/

# 2. Create Firebase project
firebase projects:create metartpay --display-name "MetartPay"

# 3. Initialize Firebase in backend
cd backend
firebase init

# 4. Install backend dependencies  
npm install

# 5. Copy environment template
cp .env.example .env
# Edit .env with your actual values

# 6. Initialize Flutter app
cd ../mobile  
flutter create metartpay_mobile .
flutter pub get
```

## Development Workflow

### Backend Development
```bash
cd backend

# Install dependencies
npm install

# Start development server
npm run dev

# Deploy to Firebase
npm run deploy

# Run tests
npm test
```

### Flutter Development  
```bash
cd mobile

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>

# Build APK
flutter build apk
```

### Database Setup (Firestore)
```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

## Testing Commands

### Blockchain Testing
```bash
# Test Ethereum connection
node -e "console.log('ETH RPC URL:', process.env.ETH_RPC_URL)"

# Test Solana connection  
solana config set --url devnet
solana balance

# Get test tokens
# Visit faucets mentioned in docs/wallet-setup.md
```

### API Testing
```bash
# Test backend locally
curl http://localhost:5001/metartpay/us-central1/api/health

# Test deployed API
curl https://us-central1-metartpay.cloudfunctions.net/api/health

# Create test merchant
curl -X POST https://your-backend-url/api/merchants \
  -H "Content-Type: application/json" \
  -d '{"business_name":"Test Store","bank_account_number":"1234567890"}'
```

## Deployment Commands

### Deploy Everything
```bash
# Deploy backend functions
cd backend && firebase deploy --only functions

# Deploy hosting  
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore

# Deploy everything at once
firebase deploy
```

### Mobile App Distribution
```bash
cd mobile

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Install on device
flutter install
```

## Monitoring & Logs

### Firebase Logs
```bash
# View function logs
firebase functions:log

# View logs for specific function
firebase functions:log --only createInvoice

# Real-time logs
firebase functions:log --follow
```

### Blockchain Monitoring
```bash
# Monitor Ethereum transactions
# Use Etherscan API or web interface

# Monitor Solana transactions  
solana transaction-history <address> --url devnet

# Check wallet balances
# Use block explorers or RPC calls
```

## Troubleshooting Commands

### Common Issues
```bash
# Fix Flutter dependency issues
flutter clean && flutter pub get

# Fix Node.js issues
rm -rf node_modules && npm install

# Reset Firebase emulators
firebase emulators:exec --only firestore "echo 'cleared'"

# Check Firebase project status
firebase projects:list
firebase use metartpay
```

### Environment Verification
```bash
# Check all required tools
node --version    # Should be 18+
flutter --version # Should be 3.x+  
firebase --version # Should be latest

# Check Firebase authentication
firebase login --reauth

# Verify project connection
firebase projects:list
```

## Demo Preparation

### Pre-Event Setup
```bash
# 1. Deploy latest code
git pull && firebase deploy

# 2. Test payment flow end-to-end
# 3. Program NFC tags with merchant URLs
# 4. Print and laminate merchant posters
# 5. Prepare demo devices with wallets
# 6. Load test crypto into buyer wallets
```

### During Demo
```bash
# Monitor logs in real-time
firebase functions:log --follow

# Check system status
curl https://your-backend-url/api/health

# Reset demo data if needed
# Use admin UI to clear test transactions
```

## Security Checklist

### Before Production
- [ ] All private keys in environment variables (not code)
- [ ] Firebase security rules configured
- [ ] API rate limiting enabled  
- [ ] HTTPS enforced on all endpoints
- [ ] Input validation on all endpoints
- [ ] Audit logs enabled
- [ ] Backup procedures tested

### Environment Variables Required
```bash
# Copy from .env.example and fill in:
FIREBASE_PROJECT_ID=
ETH_PRIVATE_KEY=
SOLANA_PRIVATE_KEY=  
BYBIT_API_KEY=
JWT_SECRET=
# ... see .env.example for complete list
```