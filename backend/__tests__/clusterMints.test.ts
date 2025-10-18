import clusterMints from '../config/cluster_mints.json';

describe('cluster_mints.json', () => {
  it('has mainnet and devnet keys', () => {
    expect(clusterMints).toHaveProperty('mainnet');
    expect(clusterMints).toHaveProperty('devnet');
  });

  it('contains placeholders for USDC and USDT', () => {
    const mainnet = clusterMints.mainnet as Record<string, string>;
    const devnet = clusterMints.devnet as Record<string, string>;

    expect(mainnet).toHaveProperty('USDC');
    expect(mainnet).toHaveProperty('USDT');
    expect(typeof mainnet.USDC).toBe('string');
    expect(typeof mainnet.USDT).toBe('string');

    expect(devnet).toHaveProperty('USDC');
    expect(devnet).toHaveProperty('USDT');
    expect(typeof devnet.USDC).toBe('string');
    expect(typeof devnet.USDT).toBe('string');
  });
});
