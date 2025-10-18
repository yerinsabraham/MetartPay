/* eslint-disable @typescript-eslint/no-var-requires */
import { verifyEthTransfer } from '../src/services/ethereumService';

// shared mutable map used by the mocked provider
let mockTxs: Record<string, any> = {};

// jest will evaluate the factory at module load. The mock references mockTxs
// by closure so we can update mockTxs in tests.
jest.mock('ethers', () => {
  class JsonRpcProvider {
    url: string;
    constructor(url?: string) {
      this.url = url || 'mock';
    }
    async getTransaction(txHash: string) {
      return mockTxs[txHash] ? mockTxs[txHash].tx : null;
    }
    async getTransactionReceipt(txHash: string) {
      return mockTxs[txHash] ? mockTxs[txHash].receipt : null;
    }
  }
  const getDefaultProvider = (network?: string) => new JsonRpcProvider(`default-${network}`);
  return { JsonRpcProvider, getDefaultProvider };
});

describe('verifyEthTransfer (mocked provider)', () => {
  beforeEach(() => {
    mockTxs = {};
    // ensure provider path uses JsonRpcProvider via rpc url
    delete process.env.ETH_RPC_URL;
    delete process.env.ALCHEMY_API_URL;
    delete process.env.INFURA_API_URL;
  });

  it('returns success when tx and receipt match expected to and value', async () => {
    const txHash = '0x1';
    mockTxs[txHash] = {
      tx: {
        to: '0xAbC',
        from: '0xFrom',
        value: { toString: () => '1000' }
      },
      receipt: { blockNumber: 123 }
    };

    // Force use of JsonRpcProvider by setting ETH_RPC_URL
    process.env.ETH_RPC_URL = 'http://mock';

    const res = await verifyEthTransfer(txHash, '0xAbC', '1000', 'sepolia');
    expect(res.success).toBe(true);
    expect(res.txHash).toBe(txHash);
    expect(res.from).toBe('0xfrom');
    expect(res.to).toBe('0xabc');
    expect(res.valueWei).toBe('1000');
    expect(res.blockNumber).toBe(123);
  });

  it('returns not found when tx missing', async () => {
    const res = await verifyEthTransfer('0xmissing', '0xabc', undefined, 'sepolia');
    expect(res.success).toBe(false);
    expect(res.message).toMatch(/Transaction not found/);
  });

  it('detects to address mismatch', async () => {
    const txHash = '0x2';
    mockTxs[txHash] = {
      tx: {
        to: '0xDeadBeef',
        from: '0xFrom',
        value: { toString: () => '0' }
      },
      receipt: { blockNumber: 1 }
    };

    process.env.ETH_RPC_URL = 'http://mock';

    const res = await verifyEthTransfer(txHash, '0xabc', undefined, 'sepolia');
    expect(res.success).toBe(false);
    expect(res.message).toMatch(/To address mismatch/);
  });
});
