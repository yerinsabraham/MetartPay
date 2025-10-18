import fs from 'fs';

// Integration tests can take longer; increase timeout
jest.setTimeout(30000);

// Set up a lightweight mock for Firestore before requiring any app modules
const collections: Record<string, Map<string, any>> = {};
function makeCollection(name: string) {
  if (!collections[name]) collections[name] = new Map();
  return collections[name];
}
const mockDb = {
  collection: (name: string) => ({
    add: async (data: any) => {
      const id = 'doc_' + Math.random().toString(36).substring(2, 10);
      makeCollection(name).set(id, { id, ...data });
      return { id, get: async () => ({ exists: true, data: () => makeCollection(name).get(id) }), update: async () => {} };
    },
    doc: (id: string) => ({ get: async () => ({ exists: makeCollection(name).has(id), data: () => makeCollection(name).get(id) }), set: async (d: any) => makeCollection(name).set(id, d), update: async (d: any) => makeCollection(name).set(id, Object.assign({}, makeCollection(name).get(id) || {}, d)) }),
    where: (_f: string, _op: string, _v: any) => ({ get: async () => ({ empty: false, docs: Array.from(makeCollection(name).entries()).map(([id, data]) => ({ id, data: () => data })) }) })
  })
};

jest.mock('firebase-admin', () => ({ initializeApp: jest.fn(), firestore: jest.fn(() => mockDb) }));
jest.mock('../src/index', () => ({ db: mockDb }));

describe('Integration: cluster mint mapping', () => {
  it('uses mapped mint for Solana tokenPrefill when mapping exists', async () => {
    // Temporarily write a test mapping file to config
    const cfgPath = 'config/cluster_mints.json';
    const orig = fs.readFileSync(cfgPath, 'utf8');
    const testMapping = {
      mainnet: { USDC: '<mainnet-usdc-mint-test>', USDT: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB' },
      devnet: { USDC: '<devnet-usdc-mint-test>', USDT: '<devnet-usdt-mint-test>' }
    };
    fs.writeFileSync(cfgPath, JSON.stringify(testMapping, null, 2));

    // Clear cached modules so controller will pick up new mapping and our index mock
    delete require.cache[require.resolve('../src/controllers/paymentLinkController')];
    delete require.cache[require.resolve('../src/index')];
    delete require.cache[require.resolve('../config/cluster_mints.json')];

    const { PaymentLinkController } = require('../src/controllers/paymentLinkController');
    const controller = new PaymentLinkController();

    // Seed required merchant and wallet docs in mockDb
    makeCollection('merchants').set('m1', { walletsGenerated: true });
    makeCollection('wallets').set('w1', { id: 'w1', chain: 'SOL', publicAddress: 'SoLaNaPubKeyExample123', merchantId: 'm1' });

    // First check USDC mapping behavior
    const resultUSDC = await controller.createPaymentForClient({ merchantId: 'm1', amountNgn: 1000, token: 'USDC', network: 'SOL' });
    expect(resultUSDC.qrPayloads).toBeDefined();
    const clusterUSDC = resultUSDC.cluster as string;
    if (clusterUSDC === 'devnet') {
      expect(resultUSDC.qrPayloads.tokenPrefill).toContain('<devnet-usdc-mint-test>');
    } else {
      expect(resultUSDC.qrPayloads.tokenPrefill).toContain('<mainnet-usdc-mint-test>');
    }

    // Now check USDT mapping behavior
    const resultUSDT = await controller.createPaymentForClient({ merchantId: 'm1', amountNgn: 1000, token: 'USDT', network: 'SOL' });
    expect(resultUSDT.qrPayloads).toBeDefined();
    const clusterUSDT = resultUSDT.cluster as string;
    if (clusterUSDT === 'devnet') {
      expect(resultUSDT.qrPayloads.tokenPrefill).toContain('<devnet-usdt-mint-test>');
    } else {
      // For mainnet, controller should use the real mint from cluster_mints.json
      expect(resultUSDT.qrPayloads.tokenPrefill).toContain('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB');
    }

    // restore original mapping
    fs.writeFileSync(cfgPath, orig);
  });
});
