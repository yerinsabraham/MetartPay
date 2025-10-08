export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role: 'merchant' | 'admin';
  createdAt: Date;
  updatedAt: Date;
}

export interface Merchant {
  id: string;
  userId: string;
  businessName: string;
  bankAccountNumber: string;
  bankName: string;
  bankAccountName: string;
  kycStatus: 'pending' | 'verified' | 'rejected';
  walletsGenerated?: boolean;
  walletsGeneratedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface Invoice {
  id: string;
  merchantId: string;
  reference: string;
  amountNaira: number;
  amountCrypto: number;
  cryptoSymbol: 'USDT' | 'USDC';
  chain: 'ETH' | 'BSC' | 'SOL';
  receivingAddress: string;
  receivingAddressDerivationIndex?: number;
  status: 'pending' | 'paid' | 'failed' | 'expired';
  createdAt: Date;
  updatedAt: Date;
  paidAt?: Date;
  txHash?: string;
  feeNaira: number;
  fxRate: number;
  metadata?: Record<string, any>;
}

export interface Wallet {
  id: string;
  merchantId: string;
  chain: 'ETH' | 'BSC' | 'SOL';
  xpub?: string;
  publicAddress: string;
  metadata?: Record<string, any>;
  createdAt: Date;
}

export interface Transaction {
  id: string;
  paymentLinkId?: string;
  invoiceId?: string;
  merchantId: string;
  txHash: string;
  fromAddress: string;
  toAddress: string;
  amountCrypto: number;
  expectedAmount: number;
  cryptoCurrency: 'USDT' | 'USDC';
  network: 'ETH' | 'BSC' | 'MATIC';
  blockNumber: number;
  confirmations: number;
  requiredConfirmations: number;
  status: 'pending' | 'confirming' | 'confirmed' | 'failed' | 'insufficient';
  observedAt: Date;
  confirmedAt?: Date;
  gasUsed?: number;
  gasPrice?: string;
  transactionFee?: number;
  metadata?: Record<string, any>;
}

export interface MonitoredAddress {
  id: string;
  merchantId: string;
  paymentLinkId?: string;
  address: string;
  network: 'ETH' | 'BSC' | 'MATIC';
  token: 'USDT' | 'USDC';
  expectedAmount: number;
  expiresAt?: Date;
  status: 'active' | 'completed' | 'expired';
  lastCheckedBlock: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface BlockchainConfig {
  network: 'ETH' | 'BSC' | 'MATIC';
  rpcUrl: string;
  chainId: number;
  blockTime: number; // seconds
  requiredConfirmations: number;
  tokens: {
    [key: string]: {
      address: string;
      decimals: number;
    };
  };
}

export interface Payout {
  id: string;
  merchantId: string;
  amountNaira: number;
  status: 'pending' | 'sent' | 'failed';
  reference: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface PaymentLink {
  id: string;
  merchantId: string;
  title: string;
  description?: string;
  amount: number; // Amount in Naira
  currency: 'NGN';
  cryptoOptions: {
    network: string; // ETH, BSC, MATIC
    token: string;   // USDT, USDC
    address: string; // Merchant's wallet address for this network
    amount: number;  // Amount in crypto (calculated from NGN amount)
  }[];
  expiresAt?: Date;
  status: 'active' | 'inactive' | 'expired';
  createdAt: Date;
  updatedAt: Date;
  // Analytics
  totalPayments: number;
  totalAmountReceived: number;
}

export interface AuditLog {
  id: string;
  entityType: string;
  entityId: string;
  action: string;
  payload: Record<string, any>;
  userId?: string;
  createdAt: Date;
}

export interface CreateInvoiceRequest {
  merchantId: string;
  amountNaira: number;
  chain: 'ETH' | 'BSC' | 'SOL';
  token: 'USDT' | 'USDC';
  metadata?: Record<string, any>;
}

export interface CreateMerchantRequest {
  userId: string;
  businessName: string;
  bankAccountNumber: string;
  bankName: string;
  bankAccountName: string;
}

export interface CreatePayoutRequest {
  merchantId: string;
  amountNaira: number;
  reference: string;
  notes?: string;
}

export interface CreatePaymentLinkRequest {
  merchantId: string;
  title: string;
  description?: string;
  amount: number; // Amount in Naira
  networks: ('ETH' | 'BSC' | 'MATIC')[];
  tokens: ('USDT' | 'USDC')[];
  expiresAt?: string; // ISO date string
}