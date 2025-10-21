/**
 * ethereumService.ts
 *
 * Lightweight scaffold for Ethereum (Sepolia) support.
 * This file intentionally contains only minimal, dependency-free stubs so it
 * is safe to commit now and expand after PR merge.
 */

import { Provider, getDefaultProvider, JsonRpcProvider, Interface } from 'ethers';
import { getFirestore } from 'firebase-admin/firestore';

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
    // Dev-only shortcut: when dev debug is enabled and the txHash looks
    // like a simulated/test tx, return a successful verification without
    // calling external RPCs. This lets local demos and CI run without
    // external provider credentials.
    if (process.env.ENABLE_DEV_DEBUG === 'true') {
      try {
          // First, if ENABLE_DEV_IN_MEMORY is true, check the in-memory store.
          if (process.env.ENABLE_DEV_IN_MEMORY === 'true') {
            try {
              // eslint-disable-next-line @typescript-eslint/no-var-requires
              const inm = require('../dev/inMemoryStore').default;
              const found = await inm.findTransactionByTxHash(txHash);
              if (found) {
                const data: any = found.data;
                const isSynthetic = data?.metadata?.synthetic === true;
                if (isSynthetic) {
                  return {
                    success: true,
                    txHash,
                    from: data.fromAddress || 'simulated-sender',
                    to: (data.toAddress || expectedToAddress || '').toLowerCase(),
                    valueWei: expectedValueWei || (data.amountCrypto ? String(data.amountCrypto) : '0'),
                    blockNumber: data.blockNumber || 123456,
                    message: 'dev-simulated-success-based-on-inmemory',
                  };
                }
              }
            } catch (inErr) {
              console.warn('dev in-memory check failed', inErr);
            }
          }

          // Next, check if the txHash corresponds to a synthetic transaction in Firestore
          const db = getFirestore();
          const txs = await db.collection('transactions').where('txHash', '==', txHash).limit(1).get();
          if (!txs.empty) {
            const doc = txs.docs[0];
            const data: any = doc.data();
            const isSynthetic = data?.metadata?.synthetic === true;
            if (isSynthetic) {
              return {
                success: true,
                txHash,
                from: data.fromAddress || 'simulated-sender',
                to: (data.toAddress || expectedToAddress || '').toLowerCase(),
                valueWei: expectedValueWei || (data.amountCrypto ? String(data.amountCrypto) : '0'),
                blockNumber: data.blockNumber || 123456,
                message: 'dev-simulated-success-based-on-firestore',
              };
            }
          }
      } catch (fireErr) {
        // ignore Firestore errors in dev shortcut and fall through to RPC-based verification
        console.warn('dev shortcut firestore check failed', fireErr);
      }
      // Fallback heuristic: also accept explicit sim_ style txHash strings
      const lowered = (txHash || '').toString().toLowerCase();
      if (lowered.startsWith('sim_') || lowered.startsWith('simtest_') || lowered.includes('simulated') || lowered.includes('sim_')) {
        return {
          success: true,
          txHash,
          from: 'simulated-sender',
          to: expectedToAddress.toLowerCase(),
          valueWei: expectedValueWei || '0',
          blockNumber: 123456,
          message: 'dev-simulated-success',
        };
      }
    }
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
    let rpcUrl = rpcMap[key] || process.env.ETH_RPC_URL || process.env.ALCHEMY_API_URL || process.env.INFURA_API_URL;

    // Sanitize common placeholder values to avoid JsonRpcProvider repeatedly
    // trying to detect network (which prints "failed to detect network" loops).
    if (rpcUrl && /YOUR_INFURA_KEY|REPLACE_ME|YOUR_ALCHEMY_KEY|YOUR_API_KEY/i.test(rpcUrl)) {
      console.warn('ethereumService: RPC URL appears to be a placeholder; ignoring to avoid provider retry loops');
      rpcUrl = undefined;
    }

    // Only construct a JsonRpcProvider when we actually have a real URL. If not
    // configured, avoid creating a provider that will continuously retry
    // detecting network. In dev mode we already handle simulated txs above.
    let provider: Provider | null = null;
    if (rpcUrl) {
      try {
        provider = new JsonRpcProvider(rpcUrl);
      } catch (e) {
        console.warn('ethereumService: failed to construct JsonRpcProvider, will not use RPC provider', e);
        provider = null;
      }
    }

    if (!provider) {
      return { success: false, txHash, message: 'RPC provider not configured or failed to initialize; set ETH_RPC_URL/INFURA_API_URL or enable dev debug for simulated txs' };
    }

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

    // ERC20 verification: use ethers.Interface to decode Transfer logs robustly
    const ERC20_IFACE = new Interface(['event Transfer(address indexed from, address indexed to, uint256 value)']);
    const logs = receipt.logs || [];
    const tokenAddr = tokenContractAddress.toLowerCase();

    for (const log of logs) {
      if (!log.address) continue;
      if (log.address.toLowerCase() !== tokenAddr) continue;
      if (!log.topics || log.topics.length === 0) continue;
      try {
        const parsed: any = ERC20_IFACE.parseLog({ topics: log.topics, data: log.data });
        if (!parsed || parsed.name !== 'Transfer') continue;
        // parsed.args: [from, to, value]
        const from = (parsed.args[0] as string).toLowerCase();
        const to = (parsed.args[1] as string).toLowerCase();
        // value may be bigint or BigNumber-like; normalize to string
        const rawVal: any = parsed.args[2];
        const gotVal = typeof rawVal === 'bigint' ? rawVal.toString() : rawVal?.toString?.() || '0';

        if (to !== expectedTo) {
          return { success: false, txHash, to, message: `ERC20 to mismatch: expected ${expectedTo} got ${to}` };
        }

        if (expectedValueWei) {
          if (gotVal !== expectedValueWei) {
            return { success: false, txHash, valueWei: gotVal, message: `ERC20 value mismatch: expected ${expectedValueWei} got ${gotVal}` };
          }
        }

        return {
          success: true,
          txHash,
          from,
          to,
          valueWei: gotVal,
          blockNumber: receipt.blockNumber,
          token: tokenAddr,
        };
      } catch (e: any) {
        // non-decodable log, continue
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
