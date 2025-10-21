/* Dev-only in-memory store used when running without the Firestore emulator.
   Keep this intentionally small - provides only the operations needed by
   simulate-confirm and the dev verifier. Enabled via ENABLE_DEV_IN_MEMORY=true.
*/

type Doc = { id: string; data: any };

const transactions = new Map<string, any>();
const monitoredAddresses = new Map<string, any>();
const notifications: any[] = [];
const paymentLinks = new Map<string, any>();
const fs = require('fs');
const path = require('path');
const PERSIST_FILE = path.join(process.cwd(), 'dev_inmemory_store.json');
const PERSIST_ENABLED = process.env.ENABLE_DEV_IN_MEMORY_PERSIST === 'true';

function loadFromDisk() {
  if (!PERSIST_ENABLED) return;
  try {
    if (fs.existsSync(PERSIST_FILE)) {
      const raw = fs.readFileSync(PERSIST_FILE, 'utf8');
      const parsed = JSON.parse(raw || '{}');
      if (parsed && parsed.transactions) {
        for (const [id, data] of Object.entries(parsed.transactions)) {
          transactions.set(id, data as any);
        }
      }
      if (parsed && parsed.monitored) {
        for (const [id, data] of Object.entries(parsed.monitored)) {
          monitoredAddresses.set(id, data as any);
        }
      }
      if (parsed && parsed.paymentLinks) {
        for (const [id, data] of Object.entries(parsed.paymentLinks)) {
          paymentLinks.set(id, data as any);
        }
      }
    }
  } catch (e) {
    console.warn('Failed to load dev in-memory store from disk:', e);
  }
}

function persistToDisk() {
  if (!PERSIST_ENABLED) return;
  try {
    const obj: any = {
      transactions: Object.fromEntries(transactions.entries()),
      monitored: Object.fromEntries(monitoredAddresses.entries()),
      paymentLinks: Object.fromEntries(paymentLinks.entries()),
    };
    fs.writeFileSync(PERSIST_FILE, JSON.stringify(obj, null, 2), 'utf8');
  } catch (e) {
    console.warn('Failed to persist dev in-memory store to disk:', e);
  }
}

function genId(prefix = ''): string {
  return (prefix || '') + Math.random().toString(36).slice(2, 10);
}

export default {
  async addTransaction(tx: any) {
    const id = genId('tx_');
    const stored = { ...tx, createdAt: new Date(), updatedAt: new Date(), id };
    transactions.set(id, stored);
    try { console.log('inMemoryStore.addTransaction ->', id, stored.txHash); } catch (e) { /* ignore */ }
    persistToDisk();
    return { id };
  },

  async findTransactionByTxHash(txHash: string): Promise<Doc | null> {
    for (const [id, data] of transactions.entries()) {
      if (data && data.txHash === txHash) return { id, data };
    }
    try { console.log('inMemoryStore.findTransactionByTxHash not found', txHash); } catch (e) {}
    return null;
  },

  async getTransactionById(id: string): Promise<Doc | null> {
    const data = transactions.get(id);
    try { console.log('inMemoryStore.getTransactionById lookup', id, !!data); } catch (e) {}
    if (!data) return null;
    return { id, data };
  },

  async addNotification(n: any) {
    const id = genId('n_');
    const doc = { id, ...n, createdAt: new Date() };
    notifications.push(doc);
    return { id };
  },

  async findMonitoredByAddress(address: string) {
    const lower = (address || '').toString().toLowerCase();
    const results: Array<any> = [];
    for (const [id, data] of monitoredAddresses.entries()) {
      if (data.address && data.address.toString().toLowerCase() === lower && data.status === 'active') {
        results.push({ id, data });
      }
    }
    return results;
  },

  async updateMonitoredStatus(id: string, status: string) {
    const cur = monitoredAddresses.get(id);
    if (!cur) return false;
    monitoredAddresses.set(id, { ...cur, status, updatedAt: new Date() });
    return true;
  },

  async getPaymentLink(id: string) {
    return paymentLinks.get(id) || null;
  },

  async updatePaymentLinkTotals(id: string, incCount = 0, incAmount = 0) {
    const cur = paymentLinks.get(id) || { totalPayments: 0, totalAmountReceived: 0 };
    const updated = { ...cur, totalPayments: (cur.totalPayments || 0) + incCount, totalAmountReceived: (cur.totalAmountReceived || 0) + incAmount, updatedAt: new Date() };
    paymentLinks.set(id, updated);
    return true;
  },

  // Helper to pre-seed a monitored address for convenience in dev
  seedMonitoredAddress(addr: string, merchantId = 'dev-merchant', paymentLinkId: string | null = null) {
    const id = genId('m_');
    monitoredAddresses.set(id, { address: addr.toString().toLowerCase(), merchantId, paymentLinkId, status: 'active', createdAt: new Date() });
    return id;
  },

  // For tests / inspection
  _dump() {
    return {
      transactions: Array.from(transactions.entries()).map(([id, data]) => ({ id, data })),
      _meta: { count: transactions.size },
      monitored: Array.from(monitoredAddresses.entries()).map(([id, d]) => ({ id, data: d })),
      notifications,
      paymentLinks: Array.from(paymentLinks.entries()).map(([id, d]) => ({ id, data: d })),
    };
  }
};
