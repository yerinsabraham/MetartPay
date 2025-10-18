/**
 * Backfill script for payments.reference
 * Run from backend folder: node tools/backfill_references.js
 */
const admin = require('firebase-admin');
const crypto = require('crypto');
const bs58 = require('bs58');

if (!admin.apps.length) {
  admin.initializeApp({});
}

const db = admin.firestore();

async function generateReference() {
  const bytes = crypto.randomBytes(32);
  return bs58.encode(bytes);
}

async function run() {
  console.log('Scanning payments collection for missing references...');
  const snapshot = await db.collection('payments').where('reference', '==', null).get();
  console.log(`Found ${snapshot.size} payments with null reference`);
  let updated = 0;
  for (const doc of snapshot.docs) {
    const ref = await generateReference();
    try {
      await doc.ref.update({ reference: ref });
      updated += 1;
      console.log(`Updated ${doc.id} -> ${ref}`);
    } catch (e) {
      console.error('Failed to update', doc.id, e);
    }
  }
  console.log(`Done. Updated ${updated} documents.`);
}

run().catch(err => {
  console.error('Failed backfill:', err);
  process.exit(1);
});
