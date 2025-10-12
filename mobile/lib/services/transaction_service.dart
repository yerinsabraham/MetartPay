import 'dart:math';
// removed unused dart:convert import
import '../models/models.dart';
import 'firebase_service.dart';
import 'crypto_price_service.dart';
import '../utils/app_logger.dart';

class TransactionService {
  final FirebaseService _firebaseService = FirebaseService();
  final CryptoPriceService _cryptoPriceService = CryptoPriceService();
  
  String _generateId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Create a new payment transaction from an invoice
  Future<Transaction> createPaymentTransaction({
    required Invoice invoice,
    required String fromAddress,
    required String txHash,
    String? customerEmail,
  }) async {
    try {
      final transaction = Transaction(
        id: _generateId(),
        merchantId: invoice.merchantId,
        invoiceId: invoice.id,
        type: 'payment_received',
        status: 'completed', // Mark as completed since we have txHash
        amountNaira: invoice.amountNaira,
        amountCrypto: invoice.amountCrypto,
        cryptoSymbol: invoice.cryptoSymbol,
        chain: invoice.chain,
        fromAddress: fromAddress,
        toAddress: invoice.receivingAddress,
        txHash: txHash,
        description: 'Payment received for invoice ${invoice.reference}',
        feeNaira: invoice.feeNaira,
        feeCrypto: 0.0, // Calculate based on network
        fxRate: invoice.fxRate,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'invoiceReference': invoice.reference,
          'customerEmail': customerEmail,
        },
      );

      // Save transaction to Firebase
      await _firebaseService.saveTransaction(transaction);

      // Update invoice status
      await _firebaseService.updateInvoiceStatus(invoice.id, 'paid', txHash: txHash);

      // Update or create customer if email provided
      if (customerEmail != null) {
        await _updateCustomerFromTransaction(transaction, customerEmail);
      }

      AppLogger.d('Payment transaction created successfully: ${transaction.id}');
      return transaction;
    } catch (e) {
      AppLogger.e('Error creating payment transaction: $e', error: e);
      rethrow;
    }
  }

  // Create a withdrawal transaction
  Future<Transaction> createWithdrawalTransaction({
    required String merchantId,
    required double amountNaira,
    required String cryptoSymbol,
    required String chain,
    required String toAddress,
    required String description,
  }) async {
    try {
      // Get current crypto price for conversion
      final cryptoPrice = await _cryptoPriceService.getCryptoPrice(cryptoSymbol);
      final priceNaira = cryptoPrice?.priceInNGN ?? 1.0;
      final amountCrypto = amountNaira / priceNaira;

      final transaction = Transaction(
        id: _generateId(),
        merchantId: merchantId,
        invoiceId: '', // No invoice for withdrawals
        type: 'withdrawal',
        status: 'pending',
        amountNaira: amountNaira,
        amountCrypto: amountCrypto,
        cryptoSymbol: cryptoSymbol,
        chain: chain,
        toAddress: toAddress,
        description: description,
        feeNaira: _calculateWithdrawalFeeNaira(amountNaira),
        feeCrypto: _calculateWithdrawalFeeCrypto(amountCrypto, cryptoSymbol),
        fxRate: priceNaira,
        createdAt: DateTime.now(),
        metadata: {
          'withdrawalType': 'bank_transfer',
          'processingTime': '1-3 business days',
        },
      );

      // Save transaction to Firebase
      await _firebaseService.saveTransaction(transaction);

      AppLogger.d('Withdrawal transaction created successfully: ${transaction.id}');
      return transaction;
    } catch (e) {
      AppLogger.e('Error creating withdrawal transaction: $e', error: e);
      rethrow;
    }
  }

  // Create a fee transaction
  Future<Transaction> createFeeTransaction({
    required String merchantId,
    required String relatedTransactionId,
    required double feeNaira,
    required String cryptoSymbol,
    required String chain,
  }) async {
    try {
      final cryptoPrice = await _cryptoPriceService.getCryptoPrice(cryptoSymbol);
      final priceNaira = cryptoPrice?.priceInNGN ?? 1.0;
      final feeCrypto = feeNaira / priceNaira;

      final transaction = Transaction(
        id: _generateId(),
        merchantId: merchantId,
        invoiceId: relatedTransactionId,
        type: 'fee',
        status: 'completed',
        amountNaira: feeNaira,
        amountCrypto: feeCrypto,
        cryptoSymbol: cryptoSymbol,
        chain: chain,
        description: 'Transaction processing fee',
        feeNaira: 0.0, // No fee on fees
        feeCrypto: 0.0,
        fxRate: priceNaira,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'feeType': 'transaction_processing',
          'relatedTransactionId': relatedTransactionId,
        },
      );

      await _firebaseService.saveTransaction(transaction);
      
      AppLogger.d('Fee transaction created successfully: ${transaction.id}');
      return transaction;
    } catch (e) {
      AppLogger.e('Error creating fee transaction: $e', error: e);
      rethrow;
    }
  }

  // Get transaction history with pagination
  Future<List<Transaction>> getTransactionHistory(
    String merchantId, {
    int limit = 20,
    String? lastTransactionId,
    String? filterType,
    String? filterStatus,
  }) async {
    try {
      var transactions = await _firebaseService.getTransactions(
        merchantId,
        limit: limit,
        lastDocumentId: lastTransactionId,
      );

      // Apply filters
      if (filterType != null) {
        transactions = transactions.where((t) => t.type == filterType).toList();
      }

      if (filterStatus != null) {
        transactions = transactions.where((t) => t.status == filterStatus).toList();
      }

      return transactions;
    } catch (e) {
      AppLogger.e('Error getting transaction history: $e', error: e);
      return [];
    }
  }

  // Get transaction analytics
  Future<Map<String, dynamic>> getTransactionAnalytics(
    String merchantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _firebaseService.getMerchantAnalytics(
        merchantId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.e('Error getting transaction analytics: $e', error: e);
      return {};
    }
  }

  // Update transaction status (e.g., for webhooks)
  Future<void> updateTransactionStatus(
    String transactionId,
    String status, {
    String? txHash,
  }) async {
    try {
      await _firebaseService.updateTransactionStatus(
        transactionId,
        status,
        txHash: txHash,
      );
    } catch (e) {
      AppLogger.e('Error updating transaction status: $e', error: e);
      rethrow;
    }
  }

  // Process payment from external webhook
  Future<void> processPaymentWebhook({
    required String invoiceId,
    required String txHash,
    required String fromAddress,
    required double confirmedAmount,
    String? customerEmail,
  }) async {
    try {
      // Get the invoice
      final invoice = await _firebaseService.getInvoice(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found: $invoiceId');
      }

      // Verify amount matches (with small tolerance for crypto precision)
      final tolerance = invoice.amountCrypto * 0.01; // 1% tolerance
      if ((confirmedAmount - invoice.amountCrypto).abs() > tolerance) {
        throw Exception('Payment amount mismatch');
      }

      // Create payment transaction
      await createPaymentTransaction(
        invoice: invoice,
        fromAddress: fromAddress,
        txHash: txHash,
        customerEmail: customerEmail,
      );

      // Create fee transaction
      await createFeeTransaction(
        merchantId: invoice.merchantId,
        relatedTransactionId: invoiceId,
        feeNaira: invoice.feeNaira,
        cryptoSymbol: invoice.cryptoSymbol,
        chain: invoice.chain,
      );

      AppLogger.d('Payment webhook processed successfully for invoice: $invoiceId');
    } catch (e) {
      AppLogger.e('Error processing payment webhook: $e', error: e);
      rethrow;
    }
  }

  // Helper method to calculate withdrawal fees
  double _calculateWithdrawalFeeNaira(double amountNaira) {
    // Implement your fee structure here
    const minFee = 50.0; // Minimum fee of ₦50
    const feePercentage = 0.015; // 1.5% fee
    
    final calculatedFee = amountNaira * feePercentage;
    return max(minFee, calculatedFee);
  }

  double _calculateWithdrawalFeeCrypto(double amountCrypto, String cryptoSymbol) {
    // Network-specific fees (these should be dynamic based on network conditions)
    switch (cryptoSymbol.toUpperCase()) {
      case 'BTC':
        return 0.0005; // 0.0005 BTC
      case 'ETH':
        return 0.001; // 0.001 ETH
      case 'USDT':
        return 5.0; // 5 USDT
      case 'SOL':
        return 0.01; // 0.01 SOL
      default:
        return amountCrypto * 0.01; // 1% default
    }
  }

  // Helper method to update customer information
  Future<void> _updateCustomerFromTransaction(Transaction transaction, String email) async {
    try {
      // Check if customer already exists
      Customer? existingCustomer = await _firebaseService.getCustomerByEmail(
        transaction.merchantId,
        email,
      );

      if (existingCustomer != null) {
        // Update existing customer stats
        await _firebaseService.updateCustomerStats(
          existingCustomer.id,
          transaction.amountNaira,
        );
      } else {
        // Create new customer
        final newCustomer = Customer(
          id: _generateId(),
          merchantId: transaction.merchantId,
          email: email,
          totalTransactions: 1,
          totalSpentNaira: transaction.amountNaira,
          firstTransactionAt: transaction.createdAt,
          lastTransactionAt: transaction.createdAt,
          createdAt: transaction.createdAt,
          updatedAt: transaction.createdAt,
        );

        await _firebaseService.saveCustomer(newCustomer);
      }
    } catch (e) {
      AppLogger.e('Error updating customer from transaction: $e', error: e);
      // Don't throw - customer update failure shouldn't fail the transaction
    }
  }

  // Simulate a payment for testing (remove in production)
  Future<Transaction> simulatePayment({
    required String merchantId,
    required String invoiceId,
    String? customerEmail,
  }) async {
    try {
      final invoice = await _firebaseService.getInvoice(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      // Generate mock transaction hash
      final txHash = '0x${_generateRandomHash()}';
      final fromAddress = _generateRandomAddress(invoice.chain);

      return await createPaymentTransaction(
        invoice: invoice,
        fromAddress: fromAddress,
        txHash: txHash,
        customerEmail: customerEmail,
      );
    } catch (e) {
      AppLogger.e('Error simulating payment: $e', error: e);
      rethrow;
    }
  }

  String _generateRandomHash() {
    const chars = '0123456789abcdef';
    final random = Random();
    return List.generate(64, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateRandomAddress(String chain) {
    const chars = '0123456789abcdef';
    final random = Random();
    
    switch (chain.toUpperCase()) {
      case 'ETH':
      case 'BSC':
        return '0x${List.generate(40, (index) => chars[random.nextInt(chars.length)]).join()}';
      case 'SOL':
        const base58Chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
        return List.generate(44, (index) => base58Chars[random.nextInt(base58Chars.length)]).join();
      default:
        return List.generate(34, (index) => chars[random.nextInt(chars.length)]).join();
    }
  }
}