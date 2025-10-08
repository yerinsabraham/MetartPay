import { ethers } from 'ethers';
import { BlockchainConfig } from '../models/types';

// ERC-20 Token ABI for transfer events
const ERC20_ABI = [
  'event Transfer(address indexed from, address indexed to, uint256 value)',
  'function balanceOf(address owner) view returns (uint256)',
  'function decimals() view returns (uint8)',
];

export class BlockchainService {
  private providers: Map<string, ethers.Provider> = new Map();
  private configs: Map<string, BlockchainConfig> = new Map();

  constructor() {
    this.initializeNetworks();
  }

  private initializeNetworks() {
    // Ethereum Mainnet
    const ethConfig: BlockchainConfig = {
      network: 'ETH',
      rpcUrl: process.env.ETH_RPC_URL || 'https://mainnet.infura.io/v3/' + process.env.INFURA_PROJECT_ID,
      chainId: 1,
      blockTime: 12,
      requiredConfirmations: 3,
      tokens: {
        USDT: { address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', decimals: 6 },
        USDC: { address: '0xA0b86a33E6417A4c55F985c248c8DC2083D72209', decimals: 6 },
      },
    };

    // Binance Smart Chain
    const bscConfig: BlockchainConfig = {
      network: 'BSC',
      rpcUrl: process.env.BSC_RPC_URL || 'https://bsc-dataseed1.binance.org',
      chainId: 56,
      blockTime: 3,
      requiredConfirmations: 6,
      tokens: {
        USDT: { address: '0x55d398326f99059fF775485246999027B3197955', decimals: 18 },
        USDC: { address: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d', decimals: 18 },
      },
    };

    // Polygon (Matic)
    const maticConfig: BlockchainConfig = {
      network: 'MATIC',
      rpcUrl: process.env.MATIC_RPC_URL || 'https://polygon-rpc.com',
      chainId: 137,
      blockTime: 2,
      requiredConfirmations: 10,
      tokens: {
        USDT: { address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F', decimals: 6 },
        USDC: { address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', decimals: 6 },
      },
    };

    // Initialize providers and store configs
    [ethConfig, bscConfig, maticConfig].forEach((config) => {
      this.configs.set(config.network, config);
      this.providers.set(config.network, new ethers.JsonRpcProvider(config.rpcUrl));
    });
  }

  /**
   * Get the latest block number for a network
   */
  async getLatestBlockNumber(network: string): Promise<number> {
    const provider = this.providers.get(network);
    if (!provider) throw new Error(`Provider not found for network: ${network}`);

    return await provider.getBlockNumber();
  }

  /**
   * Get token transfer events for an address
   */
  async getTokenTransfers(
    network: string,
    tokenSymbol: string,
    toAddress: string,
    fromBlock: number,
    toBlock?: number
  ): Promise<Array<{
    txHash: string;
    fromAddress: string;
    toAddress: string;
    amount: string;
    blockNumber: number;
    tokenAddress: string;
  }>> {
    const provider = this.providers.get(network);
    const config = this.configs.get(network);
    
    if (!provider || !config) {
      throw new Error(`Network configuration not found: ${network}`);
    }

    const tokenConfig = config.tokens[tokenSymbol];
    if (!tokenConfig) {
      throw new Error(`Token ${tokenSymbol} not supported on ${network}`);
    }

    const contract = new ethers.Contract(tokenConfig.address, ERC20_ABI, provider);
    
    // Create filter for Transfer events to the specified address
    const filter = contract.filters.Transfer(null, toAddress);
    
    try {
      const events = await contract.queryFilter(
        filter,
        fromBlock,
        toBlock || 'latest'
      );

      return events.map((event: any) => ({
        txHash: event.transactionHash,
        fromAddress: event.args[0],
        toAddress: event.args[1],
        amount: ethers.formatUnits(event.args[2], tokenConfig.decimals),
        blockNumber: event.blockNumber,
        tokenAddress: tokenConfig.address,
      }));
    } catch (error) {
      console.error(`Error fetching token transfers for ${network}:`, error);
      return [];
    }
  }

  /**
   * Get transaction details by hash
   */
  async getTransactionDetails(network: string, txHash: string): Promise<{
    hash: string;
    blockNumber: number;
    confirmations: number;
    gasUsed: string;
    gasPrice: string;
    status: number;
    from: string;
    to: string;
  } | null> {
    const provider = this.providers.get(network);
    if (!provider) throw new Error(`Provider not found for network: ${network}`);

    try {
      const [tx, receipt, currentBlock] = await Promise.all([
        provider.getTransaction(txHash),
        provider.getTransactionReceipt(txHash),
        provider.getBlockNumber(),
      ]);

      if (!tx || !receipt) return null;

      return {
        hash: tx.hash,
        blockNumber: receipt.blockNumber,
        confirmations: Math.max(0, currentBlock - receipt.blockNumber + 1),
        gasUsed: receipt.gasUsed.toString(),
        gasPrice: tx.gasPrice?.toString() || '0',
        status: receipt.status || 0,
        from: tx.from,
        to: tx.to || '',
      };
    } catch (error) {
      console.error(`Error fetching transaction details for ${txHash}:`, error);
      return null;
    }
  }

  /**
   * Check if transaction has enough confirmations
   */
  async hasRequiredConfirmations(network: string, txHash: string): Promise<boolean> {
    const config = this.configs.get(network);
    if (!config) return false;

    const details = await this.getTransactionDetails(network, txHash);
    return details ? details.confirmations >= config.requiredConfirmations : false;
  }

  /**
   * Get token balance for an address
   */
  async getTokenBalance(
    network: string,
    tokenSymbol: string,
    address: string
  ): Promise<string> {
    const provider = this.providers.get(network);
    const config = this.configs.get(network);
    
    if (!provider || !config) {
      throw new Error(`Network configuration not found: ${network}`);
    }

    const tokenConfig = config.tokens[tokenSymbol];
    if (!tokenConfig) {
      throw new Error(`Token ${tokenSymbol} not supported on ${network}`);
    }

    try {
      const contract = new ethers.Contract(tokenConfig.address, ERC20_ABI, provider);
      const balance = await contract.balanceOf(address);
      return ethers.formatUnits(balance, tokenConfig.decimals);
    } catch (error) {
      console.error(`Error fetching balance for ${address}:`, error);
      return '0';
    }
  }

  /**
   * Get network configuration
   */
  getNetworkConfig(network: string): BlockchainConfig | undefined {
    return this.configs.get(network);
  }

  /**
   * Calculate transaction fee in ETH/BNB/MATIC
   */
  calculateTransactionFee(gasUsed: string, gasPrice: string): string {
    const fee = BigInt(gasUsed) * BigInt(gasPrice);
    return ethers.formatEther(fee);
  }

  /**
   * Validate if amount meets minimum threshold (to avoid dust transactions)
   */
  isValidAmount(amount: string, expectedAmount: number, tolerance: number = 0.01): boolean {
    const received = parseFloat(amount);
    const expected = expectedAmount;
    const minAmount = expected * (1 - tolerance);
    
    return received >= minAmount;
  }

  /**
   * Get block range for monitoring (last N blocks)
   */
  async getMonitoringBlockRange(network: string, blocksBack: number = 100): Promise<{
    fromBlock: number;
    toBlock: number;
  }> {
    const currentBlock = await this.getLatestBlockNumber(network);
    return {
      fromBlock: Math.max(0, currentBlock - blocksBack),
      toBlock: currentBlock,
    };
  }

  /**
   * Get transaction receipt with retry logic
   */
  async getTransactionReceipt(network: string, txHash: string, maxRetries: number = 3): Promise<any> {
    const provider = this.providers.get(network);
    if (!provider) {
      throw new Error(`Provider not found for network: ${network}`);
    }
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const receipt = await provider.getTransactionReceipt(txHash);
        if (receipt) {
          return receipt;
        }
        
        // If no receipt yet, wait and retry
        await new Promise(resolve => setTimeout(resolve, 2000));
      } catch (error) {
        console.error(`Attempt ${attempt + 1} failed for tx ${txHash}:`, error);
        if (attempt === maxRetries - 1) throw error;
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    return null;
  }

  /**
   * Validate if an address is valid for the given network
   */
  isValidAddress(network: string, address: string): boolean {
    try {
      if (network === 'SOL') {
        // For Solana, addresses are base58 encoded and should be 32 bytes
        return address.length >= 32 && address.length <= 44;
      } else {
        // For Ethereum-based networks
        return ethers.isAddress(address);
      }
    } catch (error) {
      return false;
    }
  }

  /**
   * Get gas price for Ethereum-based networks
   */
  async getGasPrice(network: string): Promise<bigint> {
    try {
      const provider = this.providers.get(network);
      if (!provider) {
        throw new Error(`Provider not found for network: ${network}`);
      }
      const feeData = await provider.getFeeData();
      return feeData.gasPrice || BigInt(20000000000); // 20 gwei default
    } catch (error) {
      console.error(`Error getting gas price for ${network}:`, error);
      return BigInt(20000000000); // 20 gwei default
    }
  }
}