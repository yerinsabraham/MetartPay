import { WalletService } from '../services/walletService';

/**
 * Utility script to generate master wallets for MetartPay
 * Run this once to create your master wallet configuration
 */
async function generateWallets() {
  console.log('🚀 Generating MetartPay Master Wallets...\n');

  try {
    // Generate master wallet
    const masterWallet = WalletService.generateMasterWallet();

    console.log('✅ Master Wallet Generated Successfully!\n');
    console.log('📋 SAVE THESE DETAILS SECURELY:\n');
    console.log('🔐 Master Mnemonic (24 words):');
    console.log(`${masterWallet.mnemonic}\n`);
    
    console.log('💰 Default Addresses:');
    console.log(`Ethereum/BSC: ${masterWallet.ethAddress}`);
    console.log(`Solana: ${masterWallet.solanaAddress}\n`);

    console.log('⚙️  Environment Variables to Add:');
    console.log('# Add these to your backend/.env file:');
    console.log(`ETH_MNEMONIC="${masterWallet.mnemonic}"`);
    console.log(`SOLANA_MNEMONIC="${masterWallet.mnemonic}"\n`);

    console.log('🎯 Next Steps:');
    console.log('1. Save the mnemonic in a secure password manager');
    console.log('2. Add the environment variables to backend/.env');
    console.log('3. Fund the addresses with testnet tokens:');
    console.log(`   - Send Sepolia ETH to: ${masterWallet.ethAddress}`);
    console.log(`   - Send BSC testnet BNB to: ${masterWallet.ethAddress}`);
    console.log(`   - Send Solana devnet SOL to: ${masterWallet.solanaAddress}`);
    console.log('4. Get testnet USDT/USDC tokens from faucets');
    console.log('\n⚠️  SECURITY WARNING:');
    console.log('   - NEVER share your mnemonic phrase');
    console.log('   - Use testnet only for development');
    console.log('   - Create new wallets for production');

  } catch (error) {
    console.error('❌ Error generating wallets:', error);
  }
}

// Run if this file is executed directly
if (require.main === module) {
  generateWallets();
}

export { generateWallets };