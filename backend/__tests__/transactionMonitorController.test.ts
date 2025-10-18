// Mock the firebase `db` and BlockchainService to avoid initializing the full app
// Provide a collection factory that returns stable collection objects and
// supports chained query calls used by the controller (where().where().limit().get()).
const collections: Record<string, any> = {};
function makeCollection(name: string) {
  if (collections[name]) return collections[name];

  // A simple query object that supports chaining and resolves to an empty result by default
  const emptyQuery = {
    where: jest.fn().mockImplementation(() => emptyQuery),
    limit: jest.fn().mockImplementation(() => emptyQuery),
    get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
  };

  const col = {
    add: jest.fn().mockResolvedValue({ id: `${name}_doc` }),
    doc: jest.fn().mockImplementation((id: string) => ({
      get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      set: jest.fn().mockResolvedValue(undefined),
      update: jest.fn().mockResolvedValue(undefined),
    })),
    where: jest.fn().mockImplementation(() => emptyQuery),
    get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
  };

  collections[name] = col;
  return col;
}

const mockDb = {
  collection: (name: string) => makeCollection(name),
};

jest.mock('../src/index', () => ({ db: mockDb }));

jest.mock('../src/services/blockchainService', () => ({
  BlockchainService: jest.fn().mockImplementation(() => ({
    getNetworkConfig: (network: string) => ({ requiredConfirmations: 1, tokens: { ETH: {} } }),
    getLatestBlockNumber: async () => 0,
    getTokenTransfers: async () => [],
    getTransactionDetails: async () => ({ confirmations: 1, gasUsed: '0', gasPrice: '0' }),
    calculateTransactionFee: () => '0',
  }))
}));

import { TransactionMonitorController } from '../src/controllers/transactionMonitorController';
import { verifyEthTransfer } from '../src/services/ethereumService';
import { db } from '../src/index';

jest.mock('../src/services/ethereumService');

describe('TransactionMonitorController Sepolia verification', () => {
  let controller: TransactionMonitorController;

  beforeEach(() => {
    controller = new TransactionMonitorController();
    // Mock db.collection(...).where(...).get() etc if needed by controller methods
    // For processTransfer we'll call it with a monitored address object and a fake transfer
  });

  it('marks transaction unverified when verifyEthTransfer fails', async () => {
    // Arrange
    (verifyEthTransfer as jest.Mock).mockResolvedValue({ success: false, message: 'rpc fail' });

    const monitored: any = {
      id: 'm1',
      merchantId: 'merch1',
      paymentLinkId: undefined,
      address: '0xabc',
      network: 'sepolia',
      token: 'ETH',
      expectedAmount: 0.1,
    };

    const transfer = {
      txHash: '0xtx1',
      fromAddress: '0xfrom',
      toAddress: '0xabc',
      amount: '0.1',
      blockNumber: 1,
    };

    // Spy on db.collection to capture add call for transactions
    const txCol = db.collection('transactions');
    const addSpy = jest.spyOn(txCol, 'add').mockResolvedValue({ id: 'txdoc' } as any);

    // Also spy on completePayment to ensure it's NOT called for unverified tx
    const completeSpy = jest.spyOn(controller as any, 'completePayment').mockResolvedValue(undefined as any);

    // Act
    await controller['processTransfer'](monitored, transfer);

    // Assert
    expect(verifyEthTransfer).toHaveBeenCalledWith('0xtx1', '0xabc', undefined, 'sepolia');
    expect(addSpy).toHaveBeenCalled();

    // The mock add received the transaction object; check that status was 'unverified'
    const addedArg = (addSpy.mock.calls[0] && addSpy.mock.calls[0][0]) || {};
    expect(addedArg.status).toBe('unverified');

    // completePayment should not be called for unverified tx
    expect(completeSpy).not.toHaveBeenCalled();

    addSpy.mockRestore();
    completeSpy.mockRestore();
  });

  it('completes payment when verifyEthTransfer succeeds and amount sufficient', async () => {
    (verifyEthTransfer as jest.Mock).mockResolvedValue({ success: true });

    const monitored: any = {
      id: 'm2',
      merchantId: 'merch2',
      paymentLinkId: undefined,
      address: '0xdef',
      network: 'sepolia',
      token: 'ETH',
      expectedAmount: 0.1,
    };

    const transfer = {
      txHash: '0xtx2',
      fromAddress: '0xfrom',
      toAddress: '0xdef',
      amount: '0.1',
      blockNumber: 2,
    };

    // Mock db transaction add and completePayment to avoid side effects
    const addSpy = jest.spyOn(db.collection('transactions'), 'add').mockResolvedValue({ id: 'txdoc2' } as any);
    const completeSpy = jest.spyOn(controller as any, 'completePayment').mockResolvedValue(undefined as any);

    await controller['processTransfer'](monitored, transfer);

    expect(verifyEthTransfer).toHaveBeenCalledWith('0xtx2', '0xdef', undefined, 'sepolia');
    expect(completeSpy).toHaveBeenCalled();

    addSpy.mockRestore();
    completeSpy.mockRestore();
  });
});
