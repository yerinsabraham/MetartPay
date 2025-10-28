describe('Tier enforcement', () => {
  beforeEach(() => {
    jest.resetModules();
    jest.clearAllMocks();
  });

  test('throws when requested amount exceeds singleLimit for merchant tier', async () => {
    // Create a mocked db with chainable where and get
    const merchantDoc = { exists: true, data: () => ({ merchantTier: 'Tier1_BusinessName' }) };

    const mockMerchantGet = jest.fn().mockResolvedValue(merchantDoc);
    const mockTierGet = jest.fn().mockResolvedValue({ empty: false, docs: [{ id: 'Tier1_BusinessName', data: () => ({ singleLimit: 100 }) }] });
    const mockPaymentsGet = jest.fn().mockResolvedValue({ docs: [] });
    const paymentsQuery = { where: jest.fn().mockReturnThis(), get: mockPaymentsGet };

    const mockCollection = jest.fn((name: string) => {
      if (name === 'merchants') return { doc: () => ({ get: mockMerchantGet }) };
      if (name === 'config_merchantTiers') return { get: mockTierGet };
      if (name === 'payments') return paymentsQuery;
      return { get: async () => ({ empty: true, docs: [] }) };
    });

    // Mock module '../src/index' to return our mock db
    jest.doMock('../src/index', () => ({ db: { collection: mockCollection } }));

    const { enforceTierLimits } = await import('../src/lib/tierEnforcement');

    await expect(enforceTierLimits('m1', 200)).rejects.toThrow(/exceeds single-transaction limit/i);
  });

  test('passes when amount under limit', async () => {
    const merchantDoc = { exists: true, data: () => ({ merchantTier: 'Tier1_BusinessName' }) };
    const mockMerchantGet = jest.fn().mockResolvedValue(merchantDoc);
    const mockTierGet = jest.fn().mockResolvedValue({ empty: false, docs: [{ id: 'Tier1_BusinessName', data: () => ({ singleLimit: 1000, dailyLimit: 5000, monthlyLimit: 50000 }) }] });
    const mockPaymentsGet = jest.fn().mockResolvedValue({ docs: [] });
    const paymentsQuery = { where: jest.fn().mockReturnThis(), get: mockPaymentsGet };
    const mockCollection = jest.fn((name: string) => {
      if (name === 'merchants') return { doc: () => ({ get: mockMerchantGet }) };
      if (name === 'config_merchantTiers') return { get: mockTierGet };
      if (name === 'payments') return paymentsQuery;
      return { get: async () => ({ empty: true, docs: [] }) };
    });

    jest.doMock('../src/index', () => ({ db: { collection: mockCollection } }));
    const { enforceTierLimits } = await import('../src/lib/tierEnforcement');

    await expect(enforceTierLimits('m1', 500)).resolves.toBeUndefined();
  });
});
