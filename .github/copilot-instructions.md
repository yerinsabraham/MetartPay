## MetartPay — Copilot / AI agent instructions (phased, gated workflow)

Purpose: provide short, actionable guidance and a strict phase-by-phase plan. The agent MUST finish and get explicit user verification for a phase before starting the next.

1) Big picture (quick)
  - Monorepo with three primary runtime components:
    - `backend/` — Node.js + TypeScript API + Firebase Cloud Functions (build with `cd backend && npm run build`).
    - `functions/` — small Firebase functions for admin tasks.
    - `mobile/` — Flutter app (Dart + Provider). Entry: `mobile/lib/main.dart`.
  - Integrations: Firebase (Auth, Firestore, Functions, Storage, Messaging), Ethereum/BSC (`ethers`), Solana (`@solana/web3.js`). Crypto logic is server-side (backend).

2) Phased plan (ENFORCED)
  - Phase A (start now, agent must finish this first): Merchant Onboarding & KYC — registration, OTP (Termii/Twilio), multi-step business form, document upload, admin approval. Goal: 5 merchants onboarded and approved. Agent sets Phase A as in-progress and requests Yerins' explicit completion confirmation.
  - Phase B (only after user confirms Phase A): Merchant Dashboard UI — home, quick stats, recent transactions, filters, transaction detail. Build with mock data.
  - Phase C: Payment Request Generation UI — create form, QR view, shareable link. Use MockPartnerApiService; store paymentRequests in Firestore for now.
  - Phase D: Notification System — SMS (Termii/Twilio), Email (SendGrid), in-app realtime listeners. Templates + test triggers.
  - Phase E: Admin Panel — merchant management, txn monitoring, analytics, logs.
  - Phase F: Partner API abstraction & webhooks — implement `PartnerApiService` interface, add mock then swap to real provider when chosen.
  - Phase G: Testing, performance, security, and documentation — continuous across phases; final verification before integration.

3) Strict rules for the agent
  - Do not start the next phase until Yerins confirms completion of the current phase.
  - Use the repository todo list to track phase state. Update the todo list on phase start/completion.
  - Create mock data and 'simulate webhook' admin buttons where external APIs are required.

4) Developer workflows & quick commands
  - Backend dev + emulator: `cd backend; npm run dev` (emulates functions & Firestore; functions default port :5001, Firestore :8080).
  - Backend build/deploy: `cd backend; npm run build` then `npm run deploy` (`deploy:staging` available).
  - Mobile: `flutter pub get`. Run emulator/dev with dart-define flags:
    flutter run -d <device> --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=EMULATOR_FIRESTORE_HOST=127.0.0.1 --dart-define=METARTPAY_BASE_URL=http://127.0.0.1:5001/metartpay-bac2f/us-central1/api

5) Files to read first (high-signal)
  - `README.md` (root), `backend/package.json`, `backend/src/`, `mobile/pubspec.yaml`, `mobile/lib/main.dart`, `backend/tools/`, `docs/setup.md`.

6) Examples & patterns to copy
  - Partner API abstraction: implement `PartnerApiService` with `MockPartnerApiService` and a provider-specific implementation (e.g., `RoqquApiService`). Swap implementation via DI in `main.dart`.
  - PaymentRequests stored in Firestore under `paymentRequests` with fields: id, merchantId, amountNGN, cryptoAmount, cryptoType, exchangeRate, paymentAddress, status, createdAt, expiresAt.

7) When in doubt
  - Prefer server-side changes for crypto/wallet and secrets. Mobile is UI-only and should rely on backend for keys and critical logic.
  - Use mocks/simulators for partner APIs; add admin

IMPORTANT: Email verification during beta
- During early beta we will NOT enforce email verification to speed testing. Allow unverified (fake) emails for testers.
- Email verification logic exists in the codebase but is intentionally disabled for beta (default: OFF). We will not enable or recommend enabling verification until Phase A is complete and Yerins gives the go-ahead.
- Do NOT add SMS/OTP (Termii/Twilio) logic at this stage. Confirm with Yerins before changing verification transport.

8) Cloud-first testing & test-data conventions (ENFORCED)
 - For the beta we will run against the cloud Firebase project (not local emulators). This ensures real verification emails, realistic networking, and fewer setup steps.
 - Verify `mobile/lib/firebase_options.dart` points to the correct Firebase project before running locally.
 - Run the mobile app in cloud mode (no emulator flags):
   - From `mobile/` run:
     flutter pub get
     flutter run -d <device>
   - Ensure the device/emulator has internet access.
 - Test data conventions (so beta/test data is easy to find & delete):
   - Use dedicated collections for test data when feasible: `test_users`, `test_wallets`, `test_payments`.
   - Or add an `isTest: true` flag to documents created during beta:
     {
       "email": "testuser@metartpay.com",
       "isTest": true
     }
   - Example Firestore filter to list test docs:
     firestore.collection('users').where('isTest', '==', true)
 - When ready to switch to emulators later, update `main.dart` or pass the `--dart-define=USE_FIREBASE_EMULATOR=true` flag and follow emulator run steps in the docs.

9) Quick verification steps for email flow (cloud)
 - Start the app (cloud mode), register a user using a real email you can access.
 - Firebase Auth will send a verification email automatically; check inbox/spam.
 - In the app open the Email Verification screen and tap "I have verified — Continue" after clicking the link.
 - If the app still shows network/Firestore UNAVAILABLE errors, check that `mobile/lib/firebase_options.dart` projectId matches the Firebase Console project and that the device has internet.

