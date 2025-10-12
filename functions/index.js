const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Callable function to update merchant KYC status. Verifies administrative claim/server-side.
exports.updateMerchantKyc = functions.https.onCall(async (data, context) => {
  // Expected data: { merchantId: string, newStatus: string }
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request had no auth information.');
  }

  // Prefer custom claims for admin check
  const token = context.auth.token || {};
  const isAdmin = token.admin === true;

  if (!isAdmin) {
    // fallback: check users collection for isAdmin true (less secure but common)
    const uid = context.auth.uid;
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data().isAdmin !== true) {
      throw new functions.https.HttpsError('permission-denied', 'User is not an admin');
    }
  }

  const merchantId = data.merchantId;
  const newStatus = data.newStatus;

  if (!merchantId || !newStatus) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing merchantId or newStatus');
  }

  try {
    await db.collection('merchants').doc(merchantId).update({
      kycStatus: newStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('admin_audit_logs').add({
      merchantId: merchantId,
      newStatus: newStatus,
      changedBy: context.auth.uid,
      changedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (e) {
    console.error('Failed to update merchant KYC in function', e);
    throw new functions.https.HttpsError('internal', 'Failed to update merchant KYC');
  }
});

/**
 * Callable function to mark a user as admin by email.
 * - Allowed when caller has admin custom claim (normal path)
 * - OR allowed once via a one-time bootstrap secret stored in functions config: `admin.bootstrap_secret`
 *   This lets you perform a single secure bootstrap to create the initial admin.
 * The function sets a custom claim on the user, updates users/{uid}.isAdmin = true and writes an admin_audit_logs entry.
 */
exports.setAdminByEmail = functions.https.onCall(async (data, context) => {
  // Expected data: { email: string, secret?: string }
  if (!data || !data.email) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required "email" in data');
  }

  const email = String(data.email).trim().toLowerCase();

  // If caller is authenticated, prefer admin custom claim check
  let callerIsAdmin = false;
  if (context && context.auth && context.auth.token) {
    callerIsAdmin = context.auth.token.admin === true;
  }

  // If not an admin caller, check one-time bootstrap secret
  let allowedByBootstrap = false;
  if (!callerIsAdmin) {
    // Read configured bootstrap secret from functions config
    const cfg = functions.config && functions.config().admin;
    const configuredSecret = cfg && cfg.bootstrap_secret;
    const providedSecret = data.secret;

    if (configuredSecret && providedSecret && providedSecret === configuredSecret) {
      // Ensure bootstrap not already used
      const metaRef = db.collection('admin_bootstrap').doc('metadata');
      const metaDoc = await metaRef.get();
      if (!metaDoc.exists || metaDoc.data().used !== true) {
        allowedByBootstrap = true;
      } else {
        throw new functions.https.HttpsError('permission-denied', 'Bootstrap secret already used');
      }
    }
  }

  if (!callerIsAdmin && !allowedByBootstrap) {
    throw new functions.https.HttpsError('permission-denied', 'Caller is not authorized to set admin');
  }

  try {
    // Resolve user by email
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    // Preserve existing custom claims and set admin=true
    const existingClaims = userRecord.customClaims || {};
    const newClaims = Object.assign({}, existingClaims, { admin: true });
    await admin.auth().setCustomUserClaims(uid, newClaims);

    // Update users collection doc
    await db.collection('users').doc(uid).set({
      isAdmin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Write an audit log
    await db.collection('admin_audit_logs').add({
      action: 'setAdminByEmail',
      targetEmail: email,
      targetUid: uid,
      changedBy: (context && context.auth && context.auth.uid) || 'bootstrap',
      changedAt: admin.firestore.FieldValue.serverTimestamp(),
      viaBootstrap: allowedByBootstrap === true,
    });

    // If bootstrap was used, mark it so it can't be reused
    if (allowedByBootstrap) {
      await db.collection('admin_bootstrap').doc('metadata').set({
        used: true,
        usedByEmail: email,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    return { success: true, uid };
  } catch (err) {
    console.error('setAdminByEmail error', err);
    if (err.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError('not-found', 'No user found for that email');
    }
    throw new functions.https.HttpsError('internal', 'Failed to set admin');
  }
});
