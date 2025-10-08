# Crypto Wallet Setup Guide

## Testnet Setup for MetartPay Development

### 1. Ethereum Sepolia Testnet

**Network Configuration:**
- **Network Name:** Sepolia Testnet
- **RPC URL:** https://sepolia.infura.io/v3/YOUR_INFURA_KEY
- **Chain ID:** 11155111
- **Currency Symbol:** SepoliaETH
- **Block Explorer:** https://sepolia.etherscan.io/

**Get Testnet Tokens:**
1. **Sepolia ETH Faucet:** https://sepoliafaucet.com/
2. **Alternative Faucets:**
   - https://www.alchemy.com/faucets/ethereum-sepolia
   - https://faucets.chain.link/sepolia

**USDT/USDC on Sepolia:**
- **Testnet USDC:** 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
- **Testnet USDT:** 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06

### 2. BSC Testnet

**Network Configuration:**
- **Network Name:** BSC Testnet
- **RPC URL:** https://data-seed-prebsc-1-s1.binance.org:8545/
- **Chain ID:** 97
- **Currency Symbol:** tBNB
- **Block Explorer:** https://testnet.bscscan.com/

**Get Testnet Tokens:**
1. **tBNB Faucet:** https://testnet.binance.org/faucet-smart
2. **Alternative:** https://testnet.bnbchain.org/faucet-smart

**Test USDT/USDC Contracts:**
- **Test USDT:** 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
- **Test USDC:** 0x64544969ed7EBf5f083679233325356EbE738930

### 3. Solana Devnet

**Network Configuration:**
- **Cluster:** Devnet
- **RPC URL:** https://api.devnet.solana.com

**Get Devnet SOL:**
```bash
# Install Solana CLI
# https://docs.solana.com/cli/install-solana-cli-tools

# Get devnet SOL
solana airdrop 5 --url devnet

# Or use web faucet
# https://faucet.solana.com/
```

**Test USDC/USDT on Solana Devnet:**
- **USDC:** EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
- **USDT:** Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB

### 4. HD Wallet Setup

We'll use BIP44 derivation paths for generating unique addresses per invoice:

**Derivation Paths:**
- **Ethereum/BSC:** m/44'/60'/0'/0/{index}
- **Solana:** m/44'/501'/0'/0/{index}

**Environment Variables Needed:**
```env
# Main wallet seeds (24-word mnemonic phrases)
ETH_MNEMONIC="your 24 word mnemonic phrase here"
SOLANA_MNEMONIC="your 24 word solana mnemonic phrase here"

# Or individual private keys for testing
ETH_PRIVATE_KEY="0x..."
BSC_PRIVATE_KEY="0x..." # Can be same as ETH for testing
SOLANA_PRIVATE_KEY="base58_encoded_key"
```

### 5. Recommended Amounts for Testing

**Minimum Required:**
- **Sepolia ETH:** 0.05 ETH (for gas fees)
- **BSC tBNB:** 0.05 BNB (for gas fees)  
- **Solana SOL:** 2 SOL (for transactions and rent)
- **Test USDT/USDC:** 100 tokens per chain

### 6. Wallet Creation Process

1. **Create New Wallets** (recommended for security):
   ```bash
   # Generate new Ethereum wallet
   # Use MetaMask or hardware wallet
   
   # Generate new Solana wallet
   solana-keygen new --derivation-path m/44'/501'/0'/0/0
   ```

2. **Export Private Keys** (keep secure):
   - Store in environment variables
   - Never commit to Git
   - Use Firebase Functions environment config

3. **Fund Wallets:**
   - Get testnet tokens from faucets
   - Verify transactions on block explorers
   - Test small transactions between wallets

### 7. Testing Checklist

Before proceeding to backend development:

- [ ] Created Ethereum/BSC wallet with Sepolia ETH and tBNB
- [ ] Created Solana wallet with devnet SOL  
- [ ] Obtained test USDT/USDC on all chains
- [ ] Verified wallet addresses on block explorers
- [ ] Successfully sent test transactions
- [ ] Private keys securely stored
- [ ] RPC endpoints tested and working

### 8. Security Best Practices

- **Never use mainnet keys for testing**
- **Use separate wallets for each environment**
- **Store private keys in environment variables only**
- **Use hardware wallets for production**
- **Implement proper key rotation procedures**
- **Monitor wallet balances and transactions**

### 9. Useful Tools

- **MetaMask:** Browser wallet for ETH/BSC
- **Phantom:** Browser wallet for Solana  
- **Solana CLI:** Command line tools
- **Remix IDE:** Smart contract testing
- **Block Explorers:** Verify transactions