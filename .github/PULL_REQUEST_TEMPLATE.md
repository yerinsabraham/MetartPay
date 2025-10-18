## Summary

This PR adds a safe, developer-only simulation flow for creating and confirming synthetic transactions locally (or in CI using the emulators). It's intended to make UI and E2E development easier by allowing teams to exercise the "transaction confirmed" path without using real blockchain funds.

Highlights
- backend: dev-only POST `/payments/simulate-confirm` endpoint that inserts a synthetic `transactions` document and updates related `monitoredAddresses`, `paymentLinks`, and `notifications` as appropriate.
- Guarding: The endpoint is protected with both NODE_ENV !== 'production' and a request header `x-dev-simulate-key` that must match `DEV_SIMULATE_KEY`. This ensures it cannot be abused in production.
- Tools: `backend/tools/integration_simulate_test.js`, `read_transaction.js`, and `cleanup_synthetic.js` provide local verification and cleanup utilities.
- Docs: Updated Sepolia playbook with usage examples showing the dev-simulate header.

Why this is safe to merge
- All new endpoints and helpers are explicitly dev-only and require `NODE_ENV !== 'production'`.
- The additional header guard (`x-dev-simulate-key`) prevents accidental use even in non-production environments where the env var isn't set to the expected value.
- No production data or keys are included in the commit.

Verification performed
- Manual runs against local Firebase emulators (Functions + Firestore):
  - POST without `x-dev-simulate-key` -> 403 (expected)
  - POST with `x-dev-simulate-key` -> 201 and returns `transactionId`
  - `backend/tools/read_transaction.js <id>` successfully reads the synthetic document (Admin SDK + FIRESTORE_EMULATOR_HOST)
- Ran `backend/tools/integration_simulate_test.js` which asserts the 403/201 behavior and inspects Firestore contents.

How to run locally
1. Start Firebase emulators (Functions + Firestore). Ensure `FIRESTORE_EMULATOR_HOST` is set and `functions` emulator is running.
2. Set `DEV_SIMULATE_KEY` in `backend/.env` (example: `dev-local-key`).
3. Call the endpoint (functions emulator URL):
   - Example PowerShell: `curl -X POST -H "x-dev-simulate-key: dev-local-key" -H "Content-Type: application/json" -d '{"merchantId":"M","paymentLinkId":"L","toAddress":"<sol address>","amountCrypto":0.1,"cryptoCurrency":"SOL","network":"devnet"}' "http://127.0.0.1:5001/<PROJECT>/us-central1/api/payments/simulate-confirm"`
4. Verify with `node backend/tools/read_transaction.js <transactionId>` or run `node backend/tools/integration_simulate_test.js`.

Notes and next steps
- Consider adding a CI workflow that spins up the emulators and runs the integration test on PRs (sample workflow included as `.github/workflows/integration-simulate.yml` in this branch).
- After merge: follow-up work includes adding Ethereum (Sepolia) integration and adding a CI job to run this test automatically.

Co-authored-by: Dev Automation <dev@local>
<!--
  Pull Request template for MetartPay
  Reminds contributors to validate cluster mints and run tests locally before opening PRs.
-->

## Summary

Describe the change and why it is needed.

## Checklist
- [ ] I ran backend tests: `cd backend && npm test`
- [ ] I ran the cluster mints validator locally: `cd backend && npm run validate:cluster-mints`
- [ ] I did NOT commit any service account keys or secrets.
- [ ] If I added or updated `backend/config/cluster_mints.json`, I verified the mint addresses are authoritative and not placeholder values.

Notes for reviewers: if this PR modifies `backend/config/cluster_mints.json`, CI will run the validator and fail if placeholders or invalid mints are present. Please provide authoritative mint addresses and/or a verification link in the PR description.
