Tools README

This folder contains small helper scripts used during local development and testing.

integration_simulate_test.js
- Runs a POST to the simulate-confirm endpoint and verifies a transaction was written to the Firestore emulator using the Admin SDK.
- Usage (from project root):
  - Start emulators: `cd backend; npm run build; firebase emulators:start --only functions,firestore`
  - Run: `node backend/tools/integration_simulate_test.js`
- Note: The simulate endpoint requires the header `x-dev-simulate-key` with the value set in `backend/.env` (default `dev-local-key`).

read_transaction.js
- Read a transaction by ID using the Admin SDK (bypasses security rules in emulator).
- Usage:
  - PowerShell:
    ```powershell
    Set-Location backend
    $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
    node tools\read_transaction.js <transactionId>
    ```

cleanup_synthetic.js
- Deletes synthetic transactions (documents where `metadata.synthetic === true`) older than 3 days.
- Usage:
  - PowerShell:
    ```powershell
    Set-Location backend
    $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
    node tools\cleanup_synthetic.js
    ```

Notes
- All tools are intended to run against the Firestore emulator (set `FIRESTORE_EMULATOR_HOST`).
- These are development helpers and should NOT be run against production.
