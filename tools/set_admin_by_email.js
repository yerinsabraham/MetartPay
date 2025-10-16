const admin = require('firebase-admin');

// This script uses the Firebase Admin SDK. It expects GOOGLE_APPLICATION_CREDENTIALS
// to be set to a service account JSON path (or it will use the project's default
// Application Default Credentials if available). Run with: node set_admin_by_email.js youremail@example.com

if (process.argv.length < 3) {
  console.error('Usage: node set_admin_by_email.js email');
  process.exit(2);
}

const email = process.argv[2].toLowerCase();

async function main() {
  try {
    // Initialize admin SDK with default credentials (if already initialized, skip)
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    const auth = admin.auth();
    const db = admin.firestore();

    console.log('Looking up user by email:', email);
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;
    console.log('Found user:', uid);

    // Set custom claims
    const existing = userRecord.customClaims || {};
    const newClaims = Object.assign({}, existing, { admin: true });
    await auth.setCustomUserClaims(uid, newClaims);
    console.log('Set custom claim admin=true for', uid);

    // Update Firestore users doc
    await db.collection('users').doc(uid).set({
      isAdmin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log('Updated users/' + uid + ' isAdmin=true');

    // Write audit log
    await db.collection('admin_audit_logs').add({
      action: 'setAdminByScript',
      targetEmail: email,
      targetUid: uid,
      changedBy: 'script',
      changedAt: admin.firestore.FieldValue.serverTimestamp(),
      viaBootstrap: false,
    });
    console.log('Wrote admin_audit_logs entry');

    console.log('Done. User', email, 'is now admin (uid=' + uid + ')');
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
}

main();
