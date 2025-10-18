Sepolia E2E Playbook

Purpose
- Quick end-to-end test plan to validate the payments flow using Sepolia (Ethereum testnet).
- Can be used with the simulate-confirm endpoint when quick UI/notification verification is needed without sending on-chain txs.

Pre-requisites
- Backend running locally or in a non-production environment with NODE_ENV!=production.
- Sepolia RPC configured (recommended: INFURA or ALCHEMY) and reachable. Set env: ETH_RPC_URL=https://sepolia.infura.io/v3/<YOUR_KEY>
- A Sepolia-funded test account (use faucet: https://faucet.sepolia.dev or other provider).
- Mobile app built in debug pointing to the backend (AppConfig.backendBaseUrl) and devMockCreate enabled for local testing if desired.

Environment setup (backend)
1. Copy .env example and set test RPC and keys:
   - ETH_RPC_URL=https://sepolia.infura.io/v3/<KEY>
   - PAYMENT_CLUSTER=sepolia (if the backend uses cluster mapping)
   - NODE_ENV=development
2. Start backend (from project root):
   - cd backend; npm install; npm run dev

Simulate path (fast, no on-chain send)
- Use the dev-only simulate-confirm endpoint to emulate an incoming confirmed transaction.
- Request (POST): /api/payments/simulate-confirm
  Body (JSON):
  {
    "txHash": "SIMULATED_TX_12345",
    "toAddress": "<address produced by create payment qr payload or payment link>",
    "amountCrypto": "0.001",
    "cryptoCurrency": "ETH",
    "network": "sepolia",
    "merchantId": "<merchant id>",
    "paymentLinkId": "<optional payment link id>"
  }
- Expected outcome:
  - A transaction doc is added to Firestore in `transactions` collection with status 'confirmed'.
  - `monitoredAddresses` that match the toAddress become `completed`.
  - `paymentLinks` totals incremented (if linked).
  - A `notifications` record appears for the merchant.
  Also ensure you send the dev simulate header. Set the environment variable in your backend .env or environment:

  ```
  DEV_SIMULATE_KEY=dev-local-key
  ```
  
  Include the header `x-dev-simulate-key` with that value in your POST. Example using PowerShell:

  ```powershell
  $body = @{ txHash='SIM_X'; toAddress='addr'; amountCrypto='0.001'; cryptoCurrency='ETH'; network='sepolia'; merchantId='dev-merchant-1' } | ConvertTo-Json
  Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api/payments/simulate-confirm' -Body $body -ContentType 'application/json' -Headers @{ 'x-dev-simulate-key' = 'dev-local-key' }
  ```

Live on-chain path (full validation)
1. Create a payment in the app targeting network: sepolia and cryptoCurrency: ETH.
2. The server will return a recipient address (or prefills) in the payment qr payload; copy the address.
3. Using your Sepolia test account (MetaMask or other), send the specified amount to the address.
4. Monitor backend logs (transaction monitor) and Firestore collections `transactions`, `monitoredAddresses`, `paymentLinks`, and `notifications` for updates.

Validation checklist
- After simulate-confirm or real tx:
  - transactions/{id} exists and has status 'confirmed'
  - monitoredAddresses/{id}.status == 'completed'
  - paymentLinks/{id}.totalPayments increased
  - notifications contains an entry with type 'payment_received'
  - Mobile app shows payment success/notification for merchant if running

Troubleshooting
- If simulate-confirm returns 403, ensure NODE_ENV != 'production' when starting backend.
- If monitoredAddresses not found, check that the toAddress matches exactly the stored monitored address (check case/lowercasing rules).
- If no notification, inspect logs in backend and Firestore security rules for write permission issues.

Notes
- The simulate-confirm endpoint is intentionally dev-only. Do not enable in production environments.
- Simulated transactions add a `metadata.synthetic=true` field to help locate test records.

Author: automated-agent
Date: 2025-10-17
