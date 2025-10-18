// Small helper script to read a transaction document using Firebase Admin SDK
// Usage (PowerShell):
// $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'; node backend\tools\read_transaction.js <docId>

const admin = require('firebase-admin');

async function main() {
  const docId = process.argv[2];
  if (!docId) {
    console.error('Usage: node read_transaction.js <docId>');
    process.exit(1);
  }

  // Initialize admin app (will pick up FIRESTORE_EMULATOR_HOST when emulator is running)
  try {
    admin.initializeApp();
  } catch (e) {
    // ignore if already initialized
  }

  const db = admin.firestore();
  try {
    const ref = db.collection('transactions').doc(docId);
    const doc = await ref.get();
    if (!doc.exists) {
      console.log('Document not found');
      process.exit(0);
    }
    console.log(JSON.stringify(doc.data(), null, 2));
  } catch (err) {
    console.error('Error reading document:', err);
    process.exit(1);
  }
}

main();
