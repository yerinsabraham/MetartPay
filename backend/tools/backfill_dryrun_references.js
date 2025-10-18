const admin = require('firebase-admin');
const fs = require('fs');

// This script performs a dry-run and writes a report of payments that are
// missing 'reference' or 'cluster'. It does NOT write any changes.

// Allow running the script locally by specifying a service account JSON path
// via the SERVICE_ACCOUNT_KEY_PATH environment variable. If not provided,
// fall back to the default credential resolution (GOOGLE_APPLICATION_CREDENTIALS,
// gcloud ADC, etc.).
const serviceAccountPath = process.env.SERVICE_ACCOUNT_KEY_PATH || process.env.SERVICE_ACCOUNT_KEY || '';

if (!admin.apps.length) {
  if (serviceAccountPath) {
    if (!fs.existsSync(serviceAccountPath)) {
      console.error(`Service account file not found at: ${serviceAccountPath}`);
      console.error('Set SERVICE_ACCOUNT_KEY_PATH to a valid JSON key file for a Firebase service account.');
      process.exit(1);
    }
    // Load and initialize with explicit credentials
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } else {
    try {
      // This will attempt to use the default credentials available in the environment
      admin.initializeApp();
    } catch (e) {
      console.error('Failed to initialize firebase-admin with default credentials.');
      console.error('Options to fix:');
      console.error('- Set the environment variable GOOGLE_APPLICATION_CREDENTIALS to a service account JSON file path.');
      console.error('- Or set SERVICE_ACCOUNT_KEY_PATH to a service account JSON file path and re-run this script.');
      console.error('- Or run `gcloud auth application-default login` to provide Application Default Credentials.');
      console.error();
      console.error('Original error:', e && e.message ? e.message : e);
      process.exit(1);
    }
  }
}

const db = admin.firestore();

async function main() {
  const snapshot = await db.collection('payments').get();
  const missing = [];
  snapshot.forEach(doc => {
    const d = doc.data();
    if (!d.reference || !d.cluster) {
      missing.push({ id: doc.id, reference: d.reference || null, cluster: d.cluster || null });
    }
  });
  const out = { count: missing.length, items: missing };
  fs.writeFileSync('tools/backfill_dryrun_payments_missing_reference.json', JSON.stringify(out, null, 2));
  console.log('Dry-run complete. Wrote tools/backfill_dryrun_payments_missing_reference.json');
}

main().catch(err => { console.error(err); process.exit(1); });
