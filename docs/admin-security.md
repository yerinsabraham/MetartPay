Admin security guidance for MetartPay

Overview

This document explains how admin-only actions (KYC approval/rejection, user role changes) should be protected in production. The mobile client uses `FirebaseService.updateMerchantKycStatus` to request KYC updates. However, mobile clients must never be the sole enforcement point for admin privileges.

Recommendations

1) Use Firebase Authentication custom claims or a `users` collection
- For convenience you can store `isAdmin: true` in a `users/{uid}` document (this repo already expects that). However, storing admin flags in client-writable documents is unsafe unless protected by rules.
- Prefer setting an `admin` custom claim on the user through an admin SDK when granting admin rights.

2) Firestore Security Rules (enforce server-side)
- Example rule snippet to prevent non-admins from changing `merchants/{merchantId}.kycStatus`:

```
service cloud.firestore {
  match /databases/{database}/documents {
    match /merchants/{merchantId} {
      allow update: if request.auth != null && isAdmin(request.auth.uid);
    }

    function isAdmin(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.isAdmin == true
        || request.auth.token.admin == true;
    }
  }
}
```

- Note: The `request.auth.token.admin` refers to custom claims. Use admin SDK to set custom claims.

3) Cloud Functions for sensitive workflows
- For auditability and stronger security, implement admin actions in a callable Cloud Function or HTTP Cloud Function that verifies the caller's custom claims server-side prior to modifying Firestore. This avoids relying on client code and centralizes validation and audit logging.

4) Audit logs
- Write audit entries to a dedicated `admin_audit_logs` collection when admin actions occur. Ensure these entries are append-only in rules (no deletes or edits by non-admins).

5) Rotate credentials if leaked
- If any credentials (google-services.json, service accounts) were exposed, rotate API keys and revoke/regenerate service account keys.

6) Least-privilege and monitoring
- Ensure service accounts used by backend tools follow least privilege.
- Enable Firebase alerts and audit logs.

Implementation notes in this repo
- `FirebaseService.updateMerchantKycStatus` now writes an audit record to `admin_audit_logs`.
- The mobile app reads `users/{uid}.isAdmin` to set `AuthProvider.isAdmin`. In production prefer custom claims set via the Admin SDK.

If you want, I can prepare Cloud Function code (Node.js or Python) and an example rules file you can deploy. Let me know which you'd like.