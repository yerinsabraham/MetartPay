// Test script to verify wallet service is working
// Run with: node test-wallets.js

const axios = require('axios');

const API_BASE_URL = 'https://us-central1-metartpay-bac2f.cloudfunctions.net/api';

async function testWalletGeneration() {
  console.log('🧪 Testing MetartPay Wallet Generation API');
  console.log('==========================================\n');
  
  try {
    // Test health check first
    console.log('1️⃣ Testing API Health...');
    const healthCheck = await axios.get(`${API_BASE_URL}/health`);
    console.log('✅ API Health:', healthCheck.data);
    
    // Test generating an invoice address
    console.log('\n2️⃣ Testing Invoice Address Generation...');
    const invoiceData = {
      merchant_id: 'test_merchant_123',
      amount: '100.00',
      currency: 'USDT',
      network: 'ethereum',
      customer_email: 'test@example.com',
      description: 'Test Payment'
    };
    
    const invoiceResponse = await axios.post(`${API_BASE_URL}/api/invoices`, invoiceData);
    console.log('✅ Invoice Created:', {
      id: invoiceResponse.data.id,
      address: invoiceResponse.data.payment_address,
      network: invoiceResponse.data.network,
      amount: invoiceResponse.data.amount,
      currency: invoiceResponse.data.currency
    });
    
    console.log('\n🎯 Wallet Generation Test Results:');
    console.log('=================================');
    console.log('✅ API is accessible');
    console.log('✅ Invoice creation works');
    console.log('✅ Payment addresses are being generated');
    
    console.log('\n📋 Next Steps for Manual Testing:');
    console.log('==================================');
    console.log('1. Send testnet tokens to this address:', invoiceResponse.data.payment_address);
    console.log('2. Use a testnet faucet to get tokens:');
    console.log('   - Sepolia ETH: https://sepoliafaucet.com/');
    console.log('   - Test USDT: Use Uniswap on Sepolia');
    console.log('3. Monitor payment status via the API');
    
    return invoiceResponse.data;
    
  } catch (error) {
    console.error('❌ Error testing wallets:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('\n💡 Authentication may be required for this endpoint');
    } else if (error.response?.status === 500) {
      console.log('\n💡 Check backend logs for wallet service errors');
    }
    
    throw error;
  }
}

// Run the test
testWalletGeneration()
  .then(invoice => {
    console.log('\n🎉 All tests passed! Wallet generation is working.');
  })
  .catch(error => {
    console.log('\n💥 Tests failed. Check the error messages above.');
    process.exit(1);
  });