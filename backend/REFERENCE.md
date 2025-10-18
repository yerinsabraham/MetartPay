Reference generation contract

Overview
--------
For Solana token-prefill payment flows, the backend will generate a stable, base58-encoded 32-byte "reference" value for each payment. This reference is used in the Solana Pay URI as a query parameter (`reference=<base58>`) so wallets can attach the reference to on-chain transactions or to match incoming transfers.

Generation details
------------------
- The backend generates a cryptographically-random 32-byte value using Node's `crypto.randomBytes(32)` and encodes it using `bs58`.
- The generated `reference` is stored on the payment document in Firestore at `payments/{paymentId}.reference`.
- Example value: `4s6k...` (base58 string)

URI behavior
------------
- When the server builds a wallet-native Solana QR payload, it will include the reference:
  `solana:<address>?token=<TOKEN_MINT>&amount=<AMOUNT>&reference=<BASE58_REF>`
- For address-only Solana payments (no amount), the server will still use `solana:<address>` (no `reference`).

API response changes
--------------------
- The `POST /api/payments/create` (server-side create) now returns a JSON body that includes the following fields on success:
  - `paymentId` (string)
  - `qrPayload` (string) — a wallet-native URI (preferred by the mobile client)
  - `cryptoAmount` (number)
  - `address` (string)
  - `token` (string)
  - `network` (string)
  - `reference` (string) — base58 reference value (also present inside `qrPayload` for Solana token-prefill flows)

Client requirements and safety
------------------------------
- Mobile clients should prefer `qrPayload` returned by the server and present it to the user.
- If the client must build a fallback payload, it should validate that `reference` is a base58-encoded string of plausible length (32-byte base58 encoding is typically 43-44 chars but can vary); if invalid, omit the reference.

Backfill
--------
- To backfill existing payments with missing `reference`, run from the `backend` folder:

```powershell
npm run backfill:references
```

This script will generate and write valid base58 references for payments that currently have `reference == null`.

Notes
-----
- The reference is not a cryptographic public key; it's simply a 32-byte random token used as an opaque identifier and matching key for on-chain references.
- Keep the address-only fallback for wallets that reject parameterized Solana URIs.
