// Run this file with: node generate-wallets.js
// Make sure to install dependencies first: cd backend && npm install

const { generateMnemonic, mnemonicToSeedSync } = require('bip39');
const HDKey = require('hdkey');
const { ethers } = require('ethers');
const { Keypair } = require('@solana/web3.js');

console.log('🔐 MetartPay Wallet Generation Utility');
console.log('=====================================\n');

// Generate new master wallet
console.log('Generating new master wallets...\n');

try {
  const mnemonic = generateMnemonic();
  const seed = mnemonicToSeedSync(mnemonic);
  const hdkey = HDKey.fromMasterSeed(seed);
  
  // Generate Ethereum address (index 0)
  const ethChildKey = hdkey.derive("m/44'/60'/0'/0/0");
  const ethWallet = new ethers.Wallet(ethChildKey.privateKey);
  
  // Generate Solana address (index 0) 
  const solChildKey = hdkey.derive("m/44'/501'/0'/0/0");
  const solKeypair = Keypair.fromSeed(solChildKey.privateKey.slice(0, 32));
  
  console.log('📝 SAVE THESE DETAILS SECURELY:');
  console.log('================================');
  console.log('🔑 Master Mnemonic (24 words):');
  console.log(mnemonic);
  console.log('\n💰 Ethereum Address (ETH/BSC):');
  console.log(ethWallet.address);
  console.log('\n💰 Solana Address:');
  console.log(solKeypair.publicKey.toBase58());
  
  console.log('\n⚠️  SECURITY WARNINGS:');
  console.log('===================');
  console.log('1. Store the mnemonic phrase SECURELY');
  console.log('2. Never share it with anyone');
  console.log('3. If lost, you cannot recover funds');
  console.log('4. Use different wallets for development/production');
  
  console.log('\n📋 Environment Variables to Set:');
  console.log('================================');
  console.log('# Add these to your backend/.env file:');
  console.log(`ETH_MNEMONIC="${mnemonic}"`);
  console.log(`SOLANA_MNEMONIC="${mnemonic}"`);
  
  console.log('\n🎯 Next Steps:');
  console.log('==============');
  console.log('1. Copy the mnemonic to your backend/.env file');
  console.log('2. Get testnet tokens from faucets:');
  console.log('   - Sepolia ETH: https://sepoliafaucet.com/');
  console.log('   - BSC tBNB: https://testnet.binance.org/faucet-smart');
  console.log('   - Solana SOL: solana airdrop 5 --url devnet');
  console.log('3. Send tokens to the addresses above');
  console.log('4. Test creating invoices in the mobile app');
  
} catch (error) {
  console.error('Error generating wallets:', error);
  console.log('\nMake sure you have installed dependencies:');
  console.log('cd backend && npm install');
}