# Cluster mints configuration

This directory contains `cluster_mints.json`, which maps token symbols (e.g. `USDC`, `USDT`) to their mint addresses per cluster (e.g. `mainnet`, `devnet`).

Why we have this
- Token-prefill URIs for Solana require the token's mint address. To avoid embedding incorrect or mainnet-only mints into Devnet flows (which breaks wallets), we keep a central mapping.

How to validate locally
1. Ensure you have Node.js 20 installed.
2. From the repo root run:

```powershell
Set-Location -Path 'C:\path\to\repo\backend'
npm ci
npm run validate:cluster-mints
```

3. The validator will check for common placeholder text and verify each mint decodes as a base58-encoded 32-byte value. Optionally, add `-- --rpc <solanaRpcUrl>` to check on-chain existence (requires network access).

CI enforcement
- The project includes a GitHub Actions workflow that runs tests and the validator on pushes and PRs. Any PR that leaves placeholder values in `cluster_mints.json` will fail CI.

Best practices
- Do not commit real service account JSONs or secrets.
- Verify mint addresses from authoritative sources (official token docs, Solana explorers, or token issuers) before updating `cluster_mints.json`.
