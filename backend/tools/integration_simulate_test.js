/*
Integration test: POST to simulate-confirm and verify writes in Firestore emulator.
Usage:
  # ensure emulators are running
  node backend/tools/integration_simulate_test.js

Environment variables (optional):
  FIRESTORE_EMULATOR_HOST - default '127.0.0.1:8080'
  FUNCTIONS_BASE_URL - default 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api'
*/

const axios = require('axios');
const admin = require('firebase-admin');

async function main() {
  try {
    process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
    const functionsBase = process.env.FUNCTIONS_BASE_URL || 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api';
    const url = `${functionsBase}/payments/simulate-confirm`;

    const payload = {
      txHash: `SIM_TEST_${Math.floor(Math.random() * 9000) + 1000}_${Math.floor(Date.now() / 1000)}`,
      toAddress: 'simulated-address-1',
      fromAddress: 'simulated-sender',
      amountCrypto: 0.123,
      cryptoCurrency: 'ETH',
      network: 'sepolia',
      merchantId: 'dev-merchant-1',
      paymentLinkId: ''
    };

    console.log('Posting simulate-confirm to', url);
    console.log('Payload:', payload);

    // First: attempt without header (should 403)
    try {
      await axios.post(url, payload, { timeout: 10000 });
      console.error('Expected 403 when missing header but request succeeded');
      process.exit(2);
    } catch (err) {
      const status = err.response ? err.response.status : null;
      if (status !== 403) {
        console.error('Unexpected response when missing header:', err && err.response ? err.response.data : err.message);
        process.exit(2);
      }
      console.log('Missing-header check: received expected 403');
    }

    // Now: call with correct header
    const key = process.env.DEV_SIMULATE_KEY || 'dev-local-key';
    const postResp = await axios.post(url, payload, { headers: { 'x-dev-simulate-key': key }, timeout: 10000 });
    console.log('POST response status:', postResp.status);
    console.log('POST response data:', postResp.data);

    const txId = postResp.data && postResp.data.transactionId;
    if (!txId) throw new Error('No transactionId returned from simulate endpoint');

    // Initialize Admin SDK (will talk to emulator via FIRESTORE_EMULATOR_HOST)
    try { admin.initializeApp(); } catch (e) { /* ignore if already initialized */ }
    const db = admin.firestore();

    // Read the transaction doc
    const txRef = db.collection('transactions').doc(txId);
    const txDoc = await txRef.get();
    if (!txDoc.exists) {
      console.error('Transaction document not found:', txId);
      process.exit(2);
    }
    console.log('Transaction document:');
    console.log(JSON.stringify(txDoc.data(), null, 2));

    // Fetch notifications, monitoredAddresses, paymentLinks counts
    const [notifsSnap, monSnap, plSnap] = await Promise.all([
      db.collection('notifications').where('merchantId', '==', payload.merchantId).get().catch(() => null),
      db.collection('monitoredAddresses').where('address', '==', payload.toAddress).get().catch(() => null),
      db.collection('paymentLinks').get().catch(() => null),
    ]);

    console.log(`notifications for merchant (${payload.merchantId}):`, notifsSnap ? notifsSnap.size : 'N/A');
    console.log(`monitoredAddresses matching address (${payload.toAddress}):`, monSnap ? monSnap.size : 'N/A');
    console.log('paymentLinks total count:', plSnap ? plSnap.size : 'N/A');

    console.log('\nIntegration test succeeded.');
    process.exit(0);
  } catch (err) {
    console.error('Integration test failed:', err && err.response ? err.response.data || err.response.statusText : err.message || err);
    if (err.response && err.response.data) console.error('Response data:', err.response.data);
    process.exit(1);
  }
}

main();
