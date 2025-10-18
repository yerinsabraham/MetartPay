// Local helper to delete synthetic transactions older than N days via Admin SDK
// Usage (PowerShell):
// $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'; node backend\tools\cleanup_synthetic.js

const admin = require('firebase-admin');

async function main() {
  try {
    admin.initializeApp();
    const db = admin.firestore();

    const cutoff = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000); // 3 days
    console.log('Cutoff date:', cutoff.toISOString());

    const snapshot = await db.collection('transactions')
      .where('metadata.synthetic', '==', true)
      .where('createdAt', '<=', cutoff)
      .get();

    if (snapshot.empty) {
      console.log('No synthetic transactions older than 3 days to delete');
      process.exit(0);
    }

    const batch = db.batch();
    let count = 0;
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });
    await batch.commit();
    console.log(`Deleted ${count} documents`);
    process.exit(0);
  } catch (err) {
    console.error('Cleanup failed:', err);
    process.exit(1);
  }
}

main();
