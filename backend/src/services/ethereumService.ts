/**
 * ethereumService.ts
 *
 * Lightweight scaffold for Ethereum (Sepolia) support.
 * This file intentionally contains only minimal, dependency-free stubs so it
 * is safe to commit now and expand after PR merge.
 */

import { Provider, getDefaultProvider, JsonRpcProvider } from 'ethers';

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
  // Build a provider from environment. Prefer ETH_RPC_URL, then default provider.
  try {
  const rpcUrl = process.env.ETH_RPC_URL || process.env.ALCHEMY_API_URL || process.env.INFURA_API_URL;
  const provider: Provider = rpcUrl ? new JsonRpcProvider(rpcUrl) : getDefaultProvider(network);

    // Fetch transaction and receipt
    const tx = await provider.getTransaction(txHash);
    if (!tx) {
      return { success: false, txHash, message: 'Transaction not found' };
    }

    const receipt = await provider.getTransactionReceipt(txHash);
    if (!receipt) {
      return { success: false, txHash, message: 'Transaction receipt not available yet' };
    }

    // Normalize addresses to lowercase for comparison
    const actualTo = (tx.to || '').toLowerCase();
    const expectedTo = expectedToAddress.toLowerCase();

    if (actualTo !== expectedTo) {
      return { success: false, txHash, to: actualTo, message: `To address mismatch: expected ${expectedTo} got ${actualTo}` };
    }

    // If expectedValueWei is provided, compare values
    if (expectedValueWei) {
      const txValue = tx.value ? tx.value.toString() : '0';
      if (txValue !== expectedValueWei) {
        return { success: false, txHash, valueWei: txValue, message: `Value mismatch: expected ${expectedValueWei} got ${txValue}` };
      }
    }

    return {
      success: true,
      txHash,
      from: (tx.from || '').toLowerCase(),
      to: actualTo,
      valueWei: tx.value ? tx.value.toString() : '0',
      blockNumber: receipt.blockNumber
    };
  } catch (err: any) {
    return { success: false, txHash, message: `Error verifying tx: ${err?.message || String(err)}` };
  }
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
