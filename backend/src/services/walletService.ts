import { ethers } from 'ethers';
import { Connection, PublicKey, Keypair } from '@solana/web3.js';
import { generateMnemonic, mnemonicToSeedSync } from 'bip39';
import HDKey from 'hdkey';
import { Wallet } from '../models/types';

export class WalletService {
  private ethProvider: ethers.JsonRpcProvider;
  private bscProvider: ethers.JsonRpcProvider;
  private solanaConnection: Connection;

  constructor() {
    this.ethProvider = new ethers.JsonRpcProvider(
      process.env.ETH_RPC_URL || 'https://sepolia.infura.io/v3/YOUR_KEY'
    );
    this.bscProvider = new ethers.JsonRpcProvider(
      process.env.BSC_RPC_URL || 'https://data-seed-prebsc-1-s1.binance.org:8545/'
    );
    this.solanaConnection = new Connection(
      process.env.SOLANA_RPC_URL || 'https://api.devnet.solana.com',
      'confirmed'
    );
  }

  /**
   * Generate HD wallet addresses for invoice
   */
  async generateInvoiceAddress(chain: 'ETH' | 'BSC' | 'SOL', index: number): Promise<{
    address: string;
    privateKey?: string;
  }> {
    if (chain === 'SOL') {
      return this.generateSolanaAddress(index);
    } else {
      return this.generateEthereumAddress(index);
    }
  }

  /**
   * Generate Ethereum/BSC address from HD wallet
   */
  private generateEthereumAddress(index: number): {
    address: string;
    privateKey: string;
  } {
    const mnemonic = process.env.ETH_MNEMONIC;
    const privateKey = process.env.ETH_PRIVATE_KEY;

    if (mnemonic) {
      // Use HD wallet derivation
      const seed = mnemonicToSeedSync(mnemonic);
      const hdkey = HDKey.fromMasterSeed(seed);
      const derivationPath = `m/44'/60'/0'/0/${index}`;
      const childKey = hdkey.derive(derivationPath);
      
      if (!childKey.privateKey) {
        throw new Error('Failed to derive private key');
      }
      const privateKeyHex = '0x' + childKey.privateKey.toString('hex');
      const wallet = new ethers.Wallet(privateKeyHex);
      return {
        address: wallet.address,
        privateKey: wallet.privateKey,
      };
    } else if (privateKey) {
      // Use single private key (for testing only)
      const wallet = new ethers.Wallet(privateKey);
      return {
        address: wallet.address,
        privateKey: wallet.privateKey,
      };
    } else {
      throw new Error('No Ethereum wallet configuration found');
    }
  }

  /**
   * Generate Solana address from HD wallet
   */
  private generateSolanaAddress(index: number): {
    address: string;
    privateKey?: string;
  } {
    const mnemonic = process.env.SOLANA_MNEMONIC;
    const privateKey = process.env.SOLANA_PRIVATE_KEY;

    if (mnemonic) {
      // Use HD wallet derivation for Solana
      const seed = mnemonicToSeedSync(mnemonic);
      const hdkey = HDKey.fromMasterSeed(seed);
      const derivationPath = `m/44'/501'/0'/0/${index}`;
      const childKey = hdkey.derive(derivationPath);
      
      if (!childKey.privateKey) {
        throw new Error('Failed to derive Solana private key');
      }
      const keypair = Keypair.fromSeed(childKey.privateKey.slice(0, 32));
      return {
        address: keypair.publicKey.toBase58(),
        privateKey: Buffer.from(keypair.secretKey).toString('base64'),
      };
    } else if (privateKey) {
      // Use single private key (for testing only)
      const keyBuffer = Buffer.from(privateKey, 'base64');
      const keypair = Keypair.fromSecretKey(keyBuffer);
      return {
        address: keypair.publicKey.toBase58(),
      };
    } else {
      throw new Error('No Solana wallet configuration found');
    }
  }

  /**
   * Check balance of an address
   */
  async getBalance(address: string, chain: 'ETH' | 'BSC' | 'SOL', tokenSymbol?: 'USDT' | 'USDC'): Promise<number> {
    try {
      if (chain === 'SOL') {
        return await this.getSolanaBalance(address, tokenSymbol);
      } else {
        return await this.getEthereumBalance(address, chain, tokenSymbol);
      }
    } catch (error) {
      console.error(`Error getting balance for ${address}:`, error);
      return 0;
    }
  }

  /**
   * Get Ethereum/BSC balance
   */
  private async getEthereumBalance(
    address: string,
    chain: 'ETH' | 'BSC',
    tokenSymbol?: 'USDT' | 'USDC'
  ): Promise<number> {
    const provider = chain === 'ETH' ? this.ethProvider : this.bscProvider;
    
    if (!tokenSymbol) {
      // Get native balance (ETH/BNB)
      const balance = await provider.getBalance(address);
      return parseFloat(ethers.formatEther(balance));
    } else {
      // Get token balance
      const tokenAddress = this.getTokenAddress(chain, tokenSymbol);
      const contract = new ethers.Contract(
        tokenAddress,
        ['function balanceOf(address) view returns (uint256)'],
        provider
      );
      
      const balance = await contract.balanceOf(address);
      const decimals = tokenSymbol === 'USDT' ? 6 : 6; // Both USDT and USDC typically use 6 decimals
      return parseFloat(ethers.formatUnits(balance, decimals));
    }
  }

  /**
   * Get Solana balance
   */
  private async getSolanaBalance(address: string, tokenSymbol?: 'USDT' | 'USDC'): Promise<number> {
    const publicKey = new PublicKey(address);
    
    if (!tokenSymbol) {
      // Get SOL balance
      const balance = await this.solanaConnection.getBalance(publicKey);
      return balance / 1e9; // Convert lamports to SOL
    } else {
      // Get SPL token balance (implementation needed for SPL tokens)
      // This is a placeholder - full implementation requires @solana/spl-token
      return 0;
    }
  }

  /**
   * Get token contract address
   */
  private getTokenAddress(chain: 'ETH' | 'BSC', token: 'USDT' | 'USDC'): string {
    const addresses = {
      ETH: {
        USDT: process.env.USDT_ETH_ADDRESS || '0x7169D38820dfd117C3FA1f22a697dBA58d90BA06',
        USDC: process.env.USDC_ETH_ADDRESS || '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
      },
      BSC: {
        USDT: process.env.USDT_BSC_ADDRESS || '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd',
        USDC: process.env.USDC_BSC_ADDRESS || '0x64544969ed7EBf5f083679233325356EbE738930',
      },
    };
    
    return addresses[chain][token];
  }

  /**
   * Monitor address for incoming transactions
   */
  async monitorAddress(
    address: string,
    chain: 'ETH' | 'BSC' | 'SOL',
    tokenSymbol: 'USDT' | 'USDC',
    expectedAmount: number,
    callback: (txHash: string, amount: number) => void
  ): Promise<void> {
    // This would implement real-time monitoring
    // For MVP, we'll use polling in a separate service
    console.log(`Monitoring ${address} on ${chain} for ${expectedAmount} ${tokenSymbol}`);
  }

  /**
   * Get current crypto to Naira exchange rate
   */
  async getCryptoToNairaRate(symbol: 'USDT' | 'USDC'): Promise<number> {
    // This should integrate with a price API like CoinGecko or Bybit
    // For MVP, using fixed rates
    const rates = {
      USDT: 1650, // 1 USDT = 1650 NGN (example rate)
      USDC: 1650, // 1 USDC = 1650 NGN (example rate)
    };
    
    return rates[symbol];
  }

  /**
   * Convert Naira amount to crypto
   */
  async convertNairaToCrypto(nairaAmount: number, symbol: 'USDT' | 'USDC'): Promise<number> {
    const rate = await this.getCryptoToNairaRate(symbol);
    return nairaAmount / rate;
  }

  /**
   * Generate a new master wallet (for initial setup)
   */
  static generateMasterWallet(): {
    mnemonic: string;
    ethAddress: string;
    solanaAddress: string;
  } {
    const mnemonic = generateMnemonic();
    const seed = mnemonicToSeedSync(mnemonic);
    const hdkey = HDKey.fromMasterSeed(seed);
    
    // Generate Ethereum address (index 0)
    const ethChildKey = hdkey.derive("m/44'/60'/0'/0/0");
    if (!ethChildKey.privateKey) {
      throw new Error('Failed to derive Ethereum private key');
    }
    const ethPrivateKeyHex = '0x' + ethChildKey.privateKey.toString('hex');
    const ethWallet = new ethers.Wallet(ethPrivateKeyHex);
    
    // Generate Solana address (index 0)
    const solChildKey = hdkey.derive("m/44'/501'/0'/0/0");
    if (!solChildKey.privateKey) {
      throw new Error('Failed to derive Solana private key');
    }
    const solKeypair = Keypair.fromSeed(solChildKey.privateKey.slice(0, 32));
    
    return {
      mnemonic,
      ethAddress: ethWallet.address,
      solanaAddress: solKeypair.publicKey.toBase58(),
    };
  }
}

export const walletService = new WalletService();