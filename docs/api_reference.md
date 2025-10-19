# MetartPay API Reference (minimal)

This file documents the backend endpoints used by the mobile app for simple integration testing and production usage.

> Note: This is a minimal reference to get Flutter integration started. For full API docs, consider adding OpenAPI/Swagger later.

---

## 1) POST /payments/simulate-confirm

Purpose: Development/testing endpoint used to create a synthetic transaction (used by integration tests and mock mode)

Path: /payments/simulate-confirm
Method: POST
Auth: Dev-only header `x-dev-simulate-key` (dev mode). Production flows use external payment monitoring.

Request JSON body:
{
  "txHash": "SIM_TEST_1234_169....",
  "toAddress": "simulated-address-1",
  "fromAddress": "simulated-sender",
  "amountCrypto": 0.123,
  "cryptoCurrency": "ETH",
  "network": "sepolia",
  "merchantId": "dev-merchant-1",
  "paymentLinkId": ""
}

Success response (201):
{
  "success": true,
  "transactionId": "<firestore-doc-id>",
  "message": "Transaction recorded"
}

Failure responses:
- 403: Missing or invalid `x-dev-simulate-key` when dev mode expected
- 400: Invalid payload
- 500: Server error

---

## 2) GET /transactions/:id

Purpose: Return transaction details and verification status from Firestore

Path: /transactions/:id
Method: GET
Auth: Application auth (or open in dev mode)

Successful response (200):
{
  "success": true,
  "transaction": {
    "id": "<docId>",
    "txHash": "0x...",
    "fromAddress": "0x...",
    "toAddress": "0x...",
    "amountCrypto": 0.123,
    "cryptoCurrency": "ETH",
    "network": "sepolia",
    "status": "confirmed|unverified|pending|insufficient|confirming|failed",
    "confirmedAt": "2025-10-19T...Z",
    "observedAt": "2025-10-19T...Z",
    "blockNumber": 12345,
    "confirmations": 12,
    "requiredConfirmations": 12,
    "metadata": { "tokenAddress": "0x..." }
  }
}

Errors:
- 404: Not found
- 500: Server error

---

## 3) POST /admin/reverify/:txHash (optional admin endpoint)

Purpose: Allow manually re-running verification for a transaction (admin/dev use)

Path: /admin/reverify/:txHash
Method: POST
Auth: Admin-only (implement appropriate auth)

Request body (optional):
{
  "network": "sepolia",
  "tokenAddress": "0x..." // optional for ERC20
}

Success (200):
{
  "success": true,
  "txHash": "0x...",
  "message": "Verification re-run queued or completed",
  "result": { /* optional verification result */ }
}

---

## Webhook placeholder

The backend is prepared to emit in-app `notifications` (Firestore collection) when payments are received. Webhook delivery to merchant URLs is a future enhancement and can be added to the `sendPaymentNotification` flow.

---

## Notes for mobile developers

- Use the `simulate-confirm` endpoint for mock/dev flows. Provide `x-dev-simulate-key` header set to `dev-local-key` or the value set in your dev env.
- Query `/transactions/:id` to poll for status or listen to Firestore `notifications` collection for real-time updates.
- For production, the mobile app should use secure auth and not the `simulate-confirm` header; production flows rely on on-chain verification and monitored addresses.

---

If you'd like I can convert this to OpenAPI (YAML) so it plugs into generated SDKs for Flutter.