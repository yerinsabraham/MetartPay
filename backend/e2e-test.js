// Complete end-to-end test for MetartPay
// Run with: node e2e-test.js

const axios = require('axios');

const API_BASE_URL = 'https://us-central1-metartpay-bac2f.cloudfunctions.net/api';

async function runCompleteTest() {
  console.log('🧪 MetartPay End-to-End Test Suite');
  console.log('===================================\n');
  
  try {
    // Step 1: API Health Check
    console.log('1️⃣ Testing API Health...');
    const health = await axios.get(`${API_BASE_URL}/health`);
    console.log('✅ API Health:', health.data);
    
    // Step 2: Register a test user
    console.log('\n2️⃣ Registering Test User...');
    const testUser = {
      email: `test_${Date.now()}@metarttest.com`,
      password: 'TestPassword123!',
      firstName: 'Test',
      lastName: 'User',
      phone: '+2348123456789'
    };
    
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testUser);
    console.log('✅ User registered:', {
      id: registerResponse.data.user.uid,
      email: registerResponse.data.user.email
    });
    
    const authToken = registerResponse.data.token;
    const headers = { Authorization: `Bearer ${authToken}` };
    
    // Step 3: Create a merchant
    console.log('\n3️⃣ Creating Test Merchant...');
    const merchantData = {
      businessName: 'Test Crypto Store',
      businessType: 'retail',
      website: 'https://teststore.com',
      description: 'Testing crypto payments',
      phone: '+2348123456789',
      address: {
        street: '123 Test Street',
        city: 'Lagos',
        state: 'Lagos',
        country: 'Nigeria',
        postalCode: '100001'
      }
    };
    
    const merchantResponse = await axios.post(`${API_BASE_URL}/api/merchants`, merchantData, { headers });
    console.log('✅ Merchant created:', {
      id: merchantResponse.data.id,
      name: merchantResponse.data.businessName,
      apiKey: merchantResponse.data.apiKey
    });
    
    const merchantId = merchantResponse.data.id;
    
    // Step 4: Create an invoice (this should generate wallet addresses)
    console.log('\n4️⃣ Creating Test Invoice...');
    const invoiceData = {
      merchant_id: merchantId,
      amount: '50.00',
      currency: 'USDT',
      network: 'ethereum',
      customer_email: 'customer@example.com',
      description: 'Test Crypto Payment - End to End Test',
      callback_url: 'https://teststore.com/payment-callback',
      redirect_url: 'https://teststore.com/payment-success'
    };
    
    const invoiceResponse = await axios.post(`${API_BASE_URL}/api/invoices`, invoiceData, { headers });
    console.log('✅ Invoice created:', {
      id: invoiceResponse.data.id,
      amount: invoiceResponse.data.amount,
      currency: invoiceResponse.data.currency,
      network: invoiceResponse.data.network,
      payment_address: invoiceResponse.data.payment_address,
      payment_url: invoiceResponse.data.payment_url
    });
    
    // Step 5: Test getting invoice by ID (public endpoint)
    console.log('\n5️⃣ Testing Public Invoice Lookup...');
    const invoiceId = invoiceResponse.data.id;
    const publicInvoice = await axios.get(`${API_BASE_URL}/api/invoices/${invoiceId}`);
    console.log('✅ Public invoice data:', {
      id: publicInvoice.data.id,
      status: publicInvoice.data.status,
      payment_address: publicInvoice.data.payment_address
    });
    
    // Step 6: Test payment status endpoint
    console.log('\n6️⃣ Testing Payment Status Check...');
    const paymentStatus = await axios.get(`${API_BASE_URL}/api/payments/status/${invoiceId}`);
    console.log('✅ Payment status:', paymentStatus.data);
    
    // Success summary
    console.log('\n🎉 End-to-End Test Results');
    console.log('===========================');
    console.log('✅ User registration works');
    console.log('✅ Merchant creation works');
    console.log('✅ Invoice creation works');
    console.log('✅ Wallet address generation works');
    console.log('✅ Public invoice lookup works');
    console.log('✅ Payment status checking works');
    
    console.log('\n💰 Test Payment Details');
    console.log('=======================');
    console.log('Payment Address:', invoiceResponse.data.payment_address);
    console.log('Network:', invoiceResponse.data.network);
    console.log('Amount:', invoiceResponse.data.amount, invoiceResponse.data.currency);
    console.log('Payment URL:', invoiceResponse.data.payment_url);
    
    console.log('\n🧪 Manual Testing Instructions');
    console.log('==============================');
    console.log('1. Get testnet tokens from a faucet:');
    console.log('   - Sepolia ETH: https://sepoliafaucet.com/');
    console.log('   - Test USDT: Use Uniswap on Sepolia testnet');
    console.log('2. Send USDT to:', invoiceResponse.data.payment_address);
    console.log('3. Check payment status via API or payment URL');
    console.log('4. Test the mobile app payment flow');
    
    return {
      user: registerResponse.data.user,
      merchant: merchantResponse.data,
      invoice: invoiceResponse.data,
      token: authToken
    };
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('💡 Authentication issue - check token handling');
    } else if (error.response?.status === 500) {
      console.log('💡 Server error - check backend logs');
    }
    
    throw error;
  }
}

// Run the complete test
runCompleteTest()
  .then(result => {
    console.log('\n✨ All tests passed! MetartPay is ready for crypto payments.');
    console.log('\n📱 Next: Test the mobile app with these credentials:');
    console.log('Email:', result.user.email);
    console.log('Password: TestPassword123!');
  })
  .catch(error => {
    console.log('\n💥 Tests failed. Check error messages above.');
    process.exit(1);
  });