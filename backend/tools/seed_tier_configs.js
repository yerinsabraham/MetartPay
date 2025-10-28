const admin = require('firebase-admin');

// Uses application default credentials. Ensure the environment where this runs
// has access to the Firebase project (e.g. via `gcloud auth application-default login` or
// by setting GOOGLE_APPLICATION_CREDENTIALS pointing to a service account JSON).
// Project ID will be inferred from credentials or you can set FIREBASE_PROJECT env var.

async function main() {
  try {
    if (!admin.apps.length) {
      // Try to initialize with ADC; fall back to explicit projectId from env
      const initOptions = {};
      if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        // let admin pick it up
      }
      if (process.env.FIREBASE_PROJECT) {
        initOptions.projectId = process.env.FIREBASE_PROJECT;
      }
      admin.initializeApp(initOptions);
    }

    const db = admin.firestore();
    const T = db.collection('config_merchantTiers');

    const tiers = {
      'Tier0_Unregistered': {
        id: 'Tier0_Unregistered',
        name: 'Unregistered',
        description: 'Minimal onboarding; limited volume',
        singleLimit: 5000000,
        dailyLimit: 5000000,
        monthlyLimit: 5000000,
        cumulativeReceiptCap: 5000000,
        requiredDocuments: [],
      },
      'Tier1_BusinessName': {
        id: 'Tier1_BusinessName',
        name: 'Business Name',
        description: 'Registered business name; higher limits',
        singleLimit: 10000000,
        dailyLimit: 10000000,
        monthlyLimit: 10000000,
        cumulativeReceiptCap: 10000000,
        requiredDocuments: ['business_registration_document'],
      },
      'Tier2_LimitedCompany': {
        id: 'Tier2_LimitedCompany',
        name: 'Limited Company',
        description: 'Fully registered limited company; highest limits',
        singleLimit: 50000000,
        dailyLimit: 50000000,
        monthlyLimit: 50000000,
        cumulativeReceiptCap: 50000000,
        requiredDocuments: ['cac_certificate', 'directors_list'],
      }
    };

    console.log('Seeding tier configs to collection config_merchantTiers...');
    for (const [id, doc] of Object.entries(tiers)) {
      console.log(`Upserting ${id}...`);
      await T.doc(id).set(doc, { merge: true });
    }

    console.log('Seeding completed successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Failed to seed tier configs:', err);
    process.exit(1);
  }
}

main();
