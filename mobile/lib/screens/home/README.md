Home V2 — Non-custodial POS-first home

Purpose
- Home V2 is a simplified, non-custodial merchant dashboard focused on in-person payments (POS) and quick actions.
- It removes direct wallet management UI from the home screen to reduce user confusion; wallets remain managed deterministically and persisted for backend compatibility.

Key differences from legacy home
- No wallet balance / withdraw / payment-links shortcuts on the main dashboard.
- Primary actions: Receive Payment (Quick Receive), Create Payment (Invoice -> QR), View Transactions.
- Receive Payment uses a merchant deterministic address and shows a static QR for POS.
- Create Payment opens an invoice flow which generates a dynamic QR and listens for confirmation.

Notes for developers
- Wallets are generated via `FirebaseService.generateAndSaveMerchantWallets(merchantId)` when missing. The merchant document will include `walletsGenerated` and `walletAddresses`.
- The POS QR screen is at route `/qr-view-v2` and accepts the following navigation args: `payload`, `crypto`, `token`, `network`, `merchantId`, `paymentId`.
- The screen subscribes to `FirebaseService.watchMerchantTransactions(merchantId)` and matches by `invoiceId` (preferred) or by `toAddress` parsed from `payload`.
- Invoice status updates are attempted from the client for quick UX; for production consider moving invoice finalization to a server-side function for stronger guarantees.

Testing
- To QA the flow locally: open `/home-v2` (debug entry), tap Receive Payment, scan QR from a test wallet, then create a transaction document in Firestore under `transactions` with matching `toAddress` or `invoiceId` and `status: 'paid'` to simulate confirmation.

Security
- Wallet generation is deterministic and stored in Firestore; consider server-side generation if you need central control or if the deterministic seed is sensitive.

