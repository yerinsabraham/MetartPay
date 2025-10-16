# Firestore Security Rules for MetartPay

This folder contains a conservative set of Firestore security rules and a small PowerShell script to deploy them.

Files added:
- `firestore.rules` - security rules intended to enable client-side merchant flows for reading merchant data, creating and updating deterministic `wallets`, creating `payments` (in a limited, validated way), and creating receipts when a payment is confirmed.
- `deploy-firestore-rules.ps1` - PowerShell script that wraps `firebase deploy --only firestore:rules` for Windows environments.

High-level intent and assumptions
- The rules assume `request.auth.uid` equals a merchant's UID (`merchantId`). If your authentication model uses a different field (e.g., custom claims or a separate merchantId mapping), you MUST adapt the rules accordingly.
- The rules are intentionally conservative: most writes (transactions, invoices, payment_links) are disallowed from the client and must be performed server-side. This reduces attack surface.
- For `payments`, we permit authenticated merchants to create a `payments` document for themselves with strict shape validation. Fields the client must not set are rejected (e.g., `paidAt`, `backendProcessed`). Updates and deletes are server-only.
- `wallets` docs can be created/updated by the merchant (useful for deterministic wallet generation). Deletion is forbidden client-side.
- `receipts` can be created by merchants when they confirm a payment; updates/deletes are server-only.

Security notes and recommended production approach
- Recommended: Do NOT allow client-side creation of authoritative payments in production. Use a server endpoint (Cloud Function, Cloud Run, or your backend) to create canonical payment/invoice documents, enforce business rules, and sign/validate payloads.
- If you choose to allow client-side creation of `payments`, ensure you have additional monitoring, validation, and possibly Cloud Functions that reconcile and validate entries.
- These rules are a starting point. Review them together with your security/ops team before deploying to production.

How to deploy (Windows PowerShell)
1. Ensure Firebase CLI is installed and you're authenticated:

```powershell
npm install -g firebase-tools
firebase login
```

2. From the repository root deploy the rules to your project:

```powershell
cd infra\firestore
.\deploy-firestore-rules.ps1 -ProjectId "your-firebase-project-id"
```

3. To preview (dry-run), pass the `-DryRun` switch:

```powershell
.\deploy-firestore-rules.ps1 -ProjectId "your-firebase-project-id" -DryRun
```

Troubleshooting
- If the deploy fails, check that the Firebase CLI is installed and that the provided project ID is correct and that you have sufficient permissions to deploy rules.
- For production, consider managing rules via a CI pipeline and locking deploy permissions to a small set of service accounts.

Contact
- If you want me to scaffold a server endpoint to create payments securely (recommended), say so and I will add a Cloud Function/Express endpoint and update `PaymentsServiceV2` to call it instead of writing directly to Firestore.
