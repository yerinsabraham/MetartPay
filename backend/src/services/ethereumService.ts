/**
 * ethereumService.ts
 *
 * Lightweight scaffold for Ethereum (Sepolia) support.
 * This file intentionally contains only minimal, dependency-free stubs so it
 * is safe to commit now and expand after PR merge.
 */

export type EthNetwork = 'sepolia' | 'mainnet' | 'goerli' | string;

export interface EthVerifyResult {
  success: boolean;
  txHash?: string;
  from?: string;
  to?: string;
  valueWei?: string;
  blockNumber?: number;
  message?: string;
}

/**
 * verifyEthTransfer
 *
 * Stub for verifying an Ethereum transfer. After PR merge we'll replace this
 * with an implementation that uses ethers.js or an RPC/Alchemy provider.
 *
 * Inputs: txHash, expectedToAddress (lowercase), optional expectedValueWei
 * Output: EthVerifyResult describing whether the tx exists and matches
 */
export async function verifyEthTransfer(
  txHash: string,
  expectedToAddress: string,
  expectedValueWei?: string,
  network: EthNetwork = 'sepolia'
): Promise<EthVerifyResult> {
  // TODO: implement using ethers.js Provider + getTransaction/getTransactionReceipt
  // For now return a not-implemented result so server can import safely.
  return {
    success: false,
    txHash,
    message: 'Not implemented: replace with ethers.js provider call in a follow-up'
  };
}

/**
 * buildEthAddressQr
 *
 * Returns the plain address payload suitable for wallet-native QR handling
 * (e.g., Metamask: ethereum address). The frontend should prefer server-provided
 * address-only payloads when present.
 */
export function buildEthAddressQr(address: string): string {
  // Ethereum address-only payload: just the hex address
  return address;
}
