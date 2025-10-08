# MetartPay

A pass-through crypto checkout system that accepts USDT/USDC on Ethereum, BSC, and Solana networks, with instant merchant credit in Naira.

## Project Structure

- `backend/` - Node.js + TypeScript API with Firebase Functions
- `mobile/` - Flutter mobile app for merchants and buyers  
- `admin-ui/` - React admin dashboard
- `docs/` - Documentation and setup guides

## Supported Networks & Tokens

- **Ethereum**: USDT, USDC
- **BSC (Binance Smart Chain)**: USDT, USDC  
- **Solana**: USDT, USDC

## Features

- 🔐 Non-custodial payment processing
- 📱 Flutter mobile app with QR/NFC support
- 🔄 Real-time payment detection
- 💳 Manual conversion to Naira (MVP)
- 📊 Admin dashboard for merchant management
- 🏦 Bank transfer integration

## Getting Started

See `docs/setup.md` for detailed setup instructions.

## Phase Development

- Phase 0: Setup & Accounts ✅
- Phase 1: Backend Development 🔄  
- Phase 2: Blockchain Integration
- Phase 3: Flutter Mobile App
- Phase 4: Payment Flow
- Phase 5: Admin Tools
- Phase 6: Production Ready

## Banking Details (Demo)

**Merchant Payout Account:**
- Name: SAIBAKUMO YERINMENE ABRAHAM
- Bank: First Bank  
- Account: 3141710052

## Security Notes

- Private keys stored securely in Firebase Functions environment
- HD wallet derivation for unique invoice addresses
- All crypto operations server-side only
- No private keys on mobile devices