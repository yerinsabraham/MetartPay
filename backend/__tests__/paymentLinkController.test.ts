// Mock firestore admin SDK (partial) using an in-memory map
const collections: Record<string, Map<string, any>> = {};

function makeCollection(name: string) {
  if (!collections[name]) collections[name] = new Map();
  return collections[name];
}

// Minimal mock of Firestore DocumentReference / CollectionReference behaviour used in controller
const mockDb = {
  collection: (name: string) => ({
    add: async (data: any) => {
      const id = 'doc_' + Math.random().toString(36).substring(2, 10);
      makeCollection(name).set(id, { id, ...data });
      return {
        id,
        get: async () => ({ exists: true, data: () => makeCollection(name).get(id) }),
        update: async (upd: any) => {
          const existing = makeCollection(name).get(id) || {};
          makeCollection(name).set(id, Object.assign({}, existing, upd));
        }
      };
    },
    doc: (id: string) => ({
      get: async () => ({ exists: makeCollection(name).has(id), data: () => makeCollection(name).get(id) }),
      set: async (d: any, opts?: any) => makeCollection(name).set(id, d),
      update: async (d: any) => {
        const existing = makeCollection(name).get(id) || {};
        makeCollection(name).set(id, Object.assign({}, existing, d));
      }
    }),
    where: (_field: string, _op: string, _val: any) => ({
      get: async () => ({ empty: false, docs: Array.from(makeCollection(name).entries()).map(([id, data]) => ({ id, data: () => data })) })
    })
  })
};

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => mockDb),
}));

// Mock getFirestore export used in index.ts
jest.mock('../src/index', () => ({ db: mockDb }));

import { PaymentLinkController } from '../src/controllers/paymentLinkController';
import bs58 from 'bs58';

describe('PaymentLinkController.createPaymentForClient', () => {
  let controller: PaymentLinkController;

  beforeEach(() => {
    // Clear in-memory collections
    for (const k of Object.keys(collections)) collections[k].clear();
    controller = new PaymentLinkController();
    // Seed merchant and wallet
    makeCollection('merchants').set('m1', { walletsGenerated: true });
    makeCollection('wallets').set('w1', { id: 'w1', chain: 'SOL', publicAddress: 'SoLaNaPubKeyExample123', merchantId: 'm1' });
  });

  it('generates a base58 32-byte reference and returns qrPayloads with tokenPrefill for Solana', async () => {
    // Mock crypto.randomBytes to return deterministic 32 bytes
    jest.spyOn(require('crypto'), 'randomBytes').mockImplementationOnce(() => Buffer.alloc(32, 1));

    const result = await controller.createPaymentForClient({ merchantId: 'm1', amountNgn: 1000, token: 'USDC', network: 'SOL' });

    expect(result).toHaveProperty('paymentId');
    expect(result).toHaveProperty('qrPayload');
    expect(result).toHaveProperty('qrPayloads');
    expect(result).toHaveProperty('cluster');

    const { qrPayloads } = result as any;
    expect(qrPayloads.addressOnly).toBe('solana:solanapubkeyexample123');

    // tokenPrefill should be present and include a base58 reference that decodes to 32 bytes
    expect(qrPayloads.tokenPrefill).toMatch(/reference=/);
    const refMatch = qrPayloads.tokenPrefill.match(/reference=([A-Za-z0-9]+)/);
    expect(refMatch).not.toBeNull();
    const ref = refMatch![1];
    const decoded = bs58.decode(ref);
    expect(decoded.length).toBe(32);
  });
});
