/**
 * ethereumService.ts
 *
 * Lightweight scaffold for Ethereum (Sepolia) support.
 * This file intentionally contains only minimal, dependency-free stubs so it
 * is safe to commit now and expand after PR merge.
 */

import { Provider, getDefaultProvider, JsonRpcProvider, id as solidityId } from 'ethers';

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

export interface EvmVerifyResult {
  success: boolean;
  txHash?: string;
  from?: string;
  to?: string;
  valueWei?: string;
  blockNumber?: number;
  token?: string; // token contract address for ERC20
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
/**
 * verifyEvmTransfer
 * Generic EVM transfer verifier supporting ETH and ERC20 transfers across networks.
 */
export async function verifyEvmTransfer(
  txHash: string,
  expectedToAddress: string,
  expectedValueWei?: string,
  network: EthNetwork = 'sepolia',
  tokenContractAddress?: string // if provided, verify ERC20 transfer
): Promise<EvmVerifyResult> {
  try {
    // Select RPC env var per network
    const rpcMap: Record<string, string | undefined> = {
      sepolia: process.env.ETH_RPC_URL,
      mainnet: process.env.ETH_RPC_URL,
      polygon: process.env.POLYGON_RPC_URL,
      matic: process.env.POLYGON_RPC_URL,
      bsc: process.env.BSC_RPC_URL,
      'binance-smart-chain': process.env.BSC_RPC_URL,
    };

    const key = (network || '').toLowerCase();
    const rpcUrl = rpcMap[key] || process.env.ETH_RPC_URL || process.env.ALCHEMY_API_URL || process.env.INFURA_API_URL;
    const provider: Provider = rpcUrl ? new JsonRpcProvider(rpcUrl) : getDefaultProvider(network as any);

    const tx = await provider.getTransaction(txHash);
    if (!tx) return { success: false, txHash, message: 'Transaction not found' };

    const receipt = await provider.getTransactionReceipt(txHash);
    if (!receipt) return { success: false, txHash, message: 'Transaction receipt not available yet' };

    const expectedTo = expectedToAddress.toLowerCase();

    // If verifying native ETH transfer
    if (!tokenContractAddress) {
      const actualTo = (tx.to || '').toLowerCase();
      if (actualTo !== expectedTo) {
        return { success: false, txHash, to: actualTo, message: `To address mismatch: expected ${expectedTo} got ${actualTo}` };
      }

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
        blockNumber: receipt.blockNumber,
      };
    }

    // ERC20 verification: look for Transfer event in logs
    // Transfer(address indexed from, address indexed to, uint256 value)
  const transferTopic = solidityId('Transfer(address,address,uint256)');
    // Filter logs by txHash's receipt logs (we already have receipt)
    const logs = receipt.logs || [];
    // Normalize token contract address
    const tokenAddr = tokenContractAddress.toLowerCase();

    for (const log of logs) {
      if (!log.address) continue;
      if (log.address.toLowerCase() !== tokenAddr) continue;
      if (!log.topics || log.topics.length === 0) continue;
      if (log.topics[0] !== transferTopic) continue;

      // topics[1] = from, topics[2] = to
        try {
          const from = '0x' + log.topics[1].slice(26).toLowerCase();
          const to = '0x' + log.topics[2].slice(26).toLowerCase();
          const data = log.data; // hex encoded uint256
          const gotVal = BigInt(data);

          if (to !== expectedTo) {
            return { success: false, txHash, to, message: `ERC20 to mismatch: expected ${expectedTo} got ${to}` };
          }

          if (expectedValueWei) {
            const expectedVal = BigInt(expectedValueWei);
            if (gotVal !== expectedVal) {
              return { success: false, txHash, valueWei: gotVal.toString(), message: `ERC20 value mismatch: expected ${expectedVal.toString()} got ${gotVal.toString()}` };
            }
          }

          return {
            success: true,
            txHash,
            from,
            to,
            valueWei: gotVal.toString(),
            blockNumber: receipt.blockNumber,
            token: tokenAddr,
          };
        } catch (e: any) {
          continue;
        }
    }

    return { success: false, txHash, message: 'No matching ERC20 Transfer log found for token' };
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
