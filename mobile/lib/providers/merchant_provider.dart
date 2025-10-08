import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/crypto_wallet_service.dart';
import '../services/transaction_service.dart';

class MerchantProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final TransactionService _transactionService = TransactionService();
  
  List<Merchant> _merchants = [];
  Merchant? _currentMerchant;
  List<Invoice> _invoices = [];
  List<Transaction> _transactions = [];
  List<PaymentLink> _paymentLinks = [];
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  bool _needsSetup = false;
  bool _hasAttemptedLoad = false;

  // Getters
  List<Merchant> get merchants => _merchants;
  Merchant? get currentMerchant => _currentMerchant;
  List<Invoice> get invoices => _invoices;
  List<Transaction> get transactions => _transactions;
  List<PaymentLink> get paymentLinks => _paymentLinks;
  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsSetup => _needsSetup;
  bool get isSetupComplete => _currentMerchant?.isSetupComplete ?? false;
  bool get hasAttemptedLoad => _hasAttemptedLoad;

  // Computed getters for analytics
  double get totalRevenue {
    return _transactions
        .where((t) => t.isCompleted && t.isIncoming)
        .fold(0.0, (sum, t) => sum + t.amountNaira);
  }

  double get totalPendingAmount {
    return _invoices
        .where((invoice) => invoice.status == 'pending')
        .fold(0.0, (sum, invoice) => sum + invoice.amountNaira);
  }

  List<Invoice> get paidInvoices => _invoices.where((i) => i.isPaid).toList();

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _checkSetupStatus() {
    if (_currentMerchant != null) {
      _needsSetup = !_currentMerchant!.isSetupComplete;
    } else {
      _needsSetup = true;
    }
  }

  // Merchant Management
  Future<bool> createMerchant({
    required String businessName,
    required String bankAccountNumber,
    required String bankName,
    required String bankAccountName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final merchant = await _firebaseService.createMerchant(
        businessName: businessName,
        industry: 'General Business',
        contactEmail: '',
        fullName: 'User', // Default, should be updated later
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        bankAccountName: bankAccountName,
      );

      _merchants.add(merchant);
      _currentMerchant = merchant;
      _checkSetupStatus();

      print('Merchant created successfully: ${merchant.id}');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // New method for creating merchant with all onboarding fields
  Future<bool> createMerchantWithSetup({
    required String businessName,
    required String industry,
    required String contactEmail,
    String? businessAddress,
    required String fullName,
    String? idNumber,
    String? bvn,
    String? address,
    required String bankAccountNumber,
    required String bankName,
    required String bankAccountName,
    Map<String, String>? walletAddresses,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Create and save merchant to Firebase
      final merchant = await _firebaseService.createMerchant(
        businessName: businessName,
        industry: industry,
        contactEmail: contactEmail,
        businessAddress: businessAddress,
        fullName: fullName,
        idNumber: idNumber,
        bvn: bvn,
        address: address,
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        bankAccountName: bankAccountName,
        walletAddresses: walletAddresses ?? {},
      );

      // Update local state
      _merchants.add(merchant);
      _currentMerchant = merchant;
      _needsSetup = false;

      print('DEBUG: Successfully saved merchant to Firebase: ${merchant.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save merchant data: $e');
      print('DEBUG: Failed to save merchant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserMerchants() async {
    // Prevent multiple simultaneous loading attempts
    if (_isLoading || _hasAttemptedLoad) return;
    
    try {
      _setLoading(true);
      _setError(null);
      _hasAttemptedLoad = true;

      // Try to load from Firebase first
      try {
        _merchants = await _firebaseService.getUserMerchants();
        
        if (_merchants.isNotEmpty) {
          _currentMerchant = _merchants.first;
          // Load all related data
          await loadMerchantInvoices();
          await loadTransactions();
          await loadPaymentLinks();
          await loadCustomers();
          
          // Subscribe to real-time updates
          subscribeToRealtimeUpdates();
        }
      } catch (firebaseError) {
        print('DEBUG: Firebase load failed, trying API: $firebaseError');
        
        // Fallback to API if Firebase fails
        try {
          final merchantsData = await _apiService.getUserMerchants();
          _merchants = merchantsData.map((data) => Merchant.fromJson(data)).toList();
          
          if (_merchants.isNotEmpty) {
            _currentMerchant = _merchants.first;
            // Load all related data
            await loadMerchantInvoices();
            await loadTransactions();
            await loadPaymentLinks();
            await loadCustomers();
            
            // Subscribe to real-time updates
            subscribeToRealtimeUpdates();
          }
        } catch (apiError) {
          print('DEBUG: API load also failed: $apiError');
          _merchants = [];
          _currentMerchant = null;
        }
      }

      // Check if setup is needed
      _checkSetupStatus();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      print('DEBUG: Failed to load merchants: $e');
      
      // No merchants found - user will be guided to setup wizard
      _merchants = [];
      _currentMerchant = null;
      _checkSetupStatus();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _createSampleMerchant() {
    // Create a sample merchant for demo purposes when API fails
    final sampleMerchant = Merchant(
      id: 'demo-merchant-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo-user',
      businessName: 'My Business',
      industry: 'E-commerce',
      contactEmail: 'demo@business.com',
      businessAddress: null,
      fullName: 'Demo User',
      idNumber: null,
      bvn: null,
      address: null,
      kycStatus: 'pending',
      isSetupComplete: false,
      bankAccountNumber: '',
      bankName: '',
      bankAccountName: '',
      walletAddresses: {},
      totalBalance: 0.0,
      availableBalance: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _merchants = [sampleMerchant];
    _currentMerchant = sampleMerchant;
    _checkSetupStatus();
    notifyListeners();
    
    print('DEBUG: Created sample merchant for demo');
  }

  Future<Invoice?> createInvoice({
    required double amountNaira,
    required String cryptoSymbol,
    String? customerEmail,
    String? description,
  }) async {
    if (_currentMerchant == null) {
      _setError('No merchant selected');
      return null;
    }

    try {
      _setLoading(true);
      
      // Create a new invoice directly
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchantId: _currentMerchant!.id,
        reference: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        amountNaira: amountNaira,
        amountCrypto: 0.0, // Will be calculated later
        cryptoSymbol: cryptoSymbol,
        chain: 'ethereum', // Default chain
        receivingAddress: '', // Will be set by wallet
        status: 'pending',
        createdAt: DateTime.now(),
        feeNaira: amountNaira * 0.025, // 2.5% fee
        fxRate: 1.0, // Will be updated with real rate
      );

      _invoices.insert(0, invoice);

      // Save to Firebase
      await _firebaseService.saveInvoice(invoice);
      await loadMerchantInvoices();
      
      notifyListeners();
      return invoice;
    } catch (e) {
      _setError('Failed to create invoice: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMerchantInvoices() async {
    if (_currentMerchant == null) return;

    try {
      _invoices = await _firebaseService.getMerchantInvoices(_currentMerchant!.id);
      notifyListeners();
    } catch (e) {
      print('Failed to load invoices: $e');
      _invoices = [];
    }
  }

  Invoice? getInvoice(String invoiceId) {
    try {
      return _invoices.firstWhere((invoice) => invoice.id == invoiceId);
    } catch (e) {
      return null;
    }
  }

  void setCurrentMerchant(Merchant merchant) {
    _currentMerchant = merchant;
    notifyListeners();
    // Load invoices for the selected merchant
    loadMerchantInvoices();
  }

  void clearError() {
    _setError(null);
  }

  void resetLoadState() {
    _hasAttemptedLoad = false;
    _setLoading(false);
    _setError(null);
  }

  // Save partial setup data for mid-setup persistence
  Future<bool> savePartialSetupData(Map<String, dynamic> setupData) async {
    try {
      print('DEBUG: Starting savePartialSetupData with data: $setupData');
      _setLoading(true);
      _setError(null);

      // Check if user is authenticated
      final currentUserId = _firebaseService.currentUserId;
      print('DEBUG: Current user ID: $currentUserId');
      if (currentUserId == null) {
        throw Exception('User not authenticated. Please log in first.');
      }

      // If we have an existing merchant, update it
      if (_currentMerchant != null) {
        final updatedMerchant = _currentMerchant!.copyWith(
          businessName: setupData['businessName']?.isNotEmpty == true ? setupData['businessName'] : _currentMerchant!.businessName,
          industry: setupData['industry']?.isNotEmpty == true ? setupData['industry'] : _currentMerchant!.industry,
          contactEmail: setupData['contactEmail']?.isNotEmpty == true ? setupData['contactEmail'] : _currentMerchant!.contactEmail,
          businessAddress: setupData['businessAddress']?.isNotEmpty == true ? setupData['businessAddress'] : _currentMerchant!.businessAddress,
          fullName: setupData['fullName']?.isNotEmpty == true ? setupData['fullName'] : _currentMerchant!.fullName,
          idNumber: setupData['idNumber']?.isNotEmpty == true ? setupData['idNumber'] : _currentMerchant!.idNumber,
          bvn: setupData['bvn']?.isNotEmpty == true ? setupData['bvn'] : _currentMerchant!.bvn,
          address: setupData['address']?.isNotEmpty == true ? setupData['address'] : _currentMerchant!.address,
          bankAccountNumber: setupData['bankAccountNumber']?.isNotEmpty == true ? setupData['bankAccountNumber'] : _currentMerchant!.bankAccountNumber,
          bankName: setupData['bankName']?.isNotEmpty == true ? setupData['bankName'] : _currentMerchant!.bankName,
          bankAccountName: setupData['bankAccountName']?.isNotEmpty == true ? setupData['bankAccountName'] : _currentMerchant!.bankAccountName,
          walletAddresses: (setupData['walletAddresses'] as Map<String, String>?)?.isNotEmpty == true ? setupData['walletAddresses'] : _currentMerchant!.walletAddresses,
          updatedAt: DateTime.now(),
        );

        await _firebaseService.updateMerchant(updatedMerchant);
        _currentMerchant = updatedMerchant;
        
        // Update in merchants list
        final index = _merchants.indexWhere((m) => m.id == updatedMerchant.id);
        if (index != -1) {
          _merchants[index] = updatedMerchant;
        }
      } else {
        // Create a new partial merchant if none exists
        if (setupData['businessName']?.isNotEmpty == true) {
          final merchant = await _firebaseService.createMerchant(
            businessName: setupData['businessName'] ?? 'My Business',
            industry: setupData['industry'] ?? '',
            contactEmail: setupData['contactEmail'] ?? '',
            businessAddress: setupData['businessAddress'],
            fullName: setupData['fullName'] ?? '',
            idNumber: setupData['idNumber'],
            bvn: setupData['bvn'],
            address: setupData['address'],
            bankAccountNumber: setupData['bankAccountNumber'] ?? '',
            bankName: setupData['bankName'] ?? '',
            bankAccountName: setupData['bankAccountName'] ?? '',
            walletAddresses: setupData['walletAddresses'] ?? {},
          );
          
          _merchants.add(merchant);
          _currentMerchant = merchant;
        }
      }
      
      _checkSetupStatus();
      notifyListeners();
      print('DEBUG: Successfully saved partial setup data');
      return true;
    } catch (e) {
      _setError('Failed to save setup progress: $e');
      print('DEBUG: Failed to save partial setup: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for invoice filtering
  List<Invoice> get pendingInvoices =>
      _invoices.where((invoice) => invoice.status == 'pending').toList();

  // Setup completion methods
  Future<bool> updateMerchantSetup({
    String? industry,
    String? contactEmail,
    String? businessAddress,
    String? fullName,
    String? idNumber,
    String? bvn,
    String? address,
    String? bankAccountNumber,
    String? bankName,
    String? bankAccountName,
    Map<String, String>? walletAddresses,
  }) async {
    if (_currentMerchant == null) return false;

    try {
      _setLoading(true);
      _setError(null);

      // Create updated merchant
      final updatedMerchant = _currentMerchant!.copyWith(
        industry: industry,
        contactEmail: contactEmail,
        businessAddress: businessAddress,
        fullName: fullName,
        idNumber: idNumber,
        bvn: bvn,
        address: address,
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        bankAccountName: bankAccountName,
        walletAddresses: walletAddresses,
        isSetupComplete: _isSetupFieldsComplete(
          industry: industry ?? _currentMerchant!.industry,
          contactEmail: contactEmail ?? _currentMerchant!.contactEmail,
          fullName: fullName ?? _currentMerchant!.fullName,
          bankAccountNumber: bankAccountNumber ?? _currentMerchant!.bankAccountNumber,
          bankName: bankName ?? _currentMerchant!.bankName,
          bankAccountName: bankAccountName ?? _currentMerchant!.bankAccountName,
        ),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      final savedMerchant = await _firebaseService.updateMerchant(updatedMerchant);
      
      // Update local state
      _currentMerchant = savedMerchant;
      
      // Update in merchants list
      final index = _merchants.indexWhere((m) => m.id == savedMerchant.id);
      if (index != -1) {
        _merchants[index] = savedMerchant;
      }

      _checkSetupStatus();
      print('DEBUG: Successfully updated merchant in Firebase: ${savedMerchant.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update merchant data: $e');
      print('DEBUG: Failed to update merchant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool _isSetupFieldsComplete({
    required String industry,
    required String contactEmail,
    required String fullName,
    required String bankAccountNumber,
    required String bankName,
    required String bankAccountName,
  }) {
    return industry.isNotEmpty &&
           contactEmail.isNotEmpty &&
           fullName.isNotEmpty &&
           bankAccountNumber.isNotEmpty &&
           bankName.isNotEmpty &&
           bankAccountName.isNotEmpty;
  }

  void completeSetup() {
    if (_currentMerchant != null) {
      _needsSetup = false;
      notifyListeners();
    }
  }

  Future<bool> updateMerchantKYC({
    required String fullName,
    required String idNumber,
    required String bvn,
    required String address,
    required String idType,
  }) async {
    if (_currentMerchant == null) return false;
    
    try {
      _setLoading(true);
      _setError(null);

      // Create updated merchant with KYC info
      final updatedMerchant = _currentMerchant!.copyWith(
        fullName: fullName,
        idNumber: idNumber,
        bvn: bvn.isEmpty ? null : bvn,
        address: address,
        kycStatus: 'pending', // Set to pending after submission
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      final savedMerchant = await _firebaseService.updateMerchant(updatedMerchant);
      
      // Update local state
      _currentMerchant = savedMerchant;
      final index = _merchants.indexWhere((m) => m.id == savedMerchant.id);
      if (index != -1) {
        _merchants[index] = savedMerchant;
      }

      _checkSetupStatus();
      print('DEBUG: Successfully updated KYC data in Firebase: ${savedMerchant.id}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update KYC data: $e');
      print('DEBUG: Failed to update KYC: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Map<String, String> generateWalletAddresses() {
    // Use the new crypto wallet service for more realistic addresses
    if (_currentMerchant != null) {
      return CryptoWalletService.generateWalletAddresses(
        merchantId: _currentMerchant!.id,
        userId: _currentMerchant!.userId,
      );
    } else {
      // Fallback for when no merchant is set
      return CryptoWalletService.generateWalletAddresses(
        merchantId: 'demo-merchant',
        userId: 'demo-user',
      );
    }
  }

  List<Map<String, dynamic>> getWalletNetworks() {
    return CryptoWalletService.getSupportedNetworks();
  }

  // Transaction Management Methods
  Future<void> loadTransactions() async {
    if (_currentMerchant == null) return;

    try {
      _transactions = await _transactionService.getTransactionHistory(_currentMerchant!.id);
      notifyListeners();
    } catch (e) {
      print('Failed to load transactions: $e');
      _transactions = [];
    }
  }

  Future<void> loadPaymentLinks() async {
    if (_currentMerchant == null) return;

    try {
      _paymentLinks = await _firebaseService.getPaymentLinks(_currentMerchant!.id);
      notifyListeners();
    } catch (e) {
      print('Failed to load payment links: $e');
      _paymentLinks = [];
    }
  }

  Future<void> loadCustomers() async {
    if (_currentMerchant == null) return;

    try {
      _customers = await _firebaseService.getCustomers(_currentMerchant!.id);
      notifyListeners();
    } catch (e) {
      print('Failed to load customers: $e');
      _customers = [];
    }
  }

  // Create a new payment link
  Future<PaymentLink?> createPaymentLink({
    required String title,
    String? description,
    required double amountNaira,
    String? customerEmail,
    String? customerName,
    int? usageLimit,
    DateTime? expiresAt,
  }) async {
    if (_currentMerchant == null) {
      _setError('No merchant selected');
      return null;
    }

    try {
      _setLoading(true);

      final paymentLink = PaymentLink(
        id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
        merchantId: _currentMerchant!.id,
        title: title,
        description: description,
        amountNaira: amountNaira,
        customerEmail: customerEmail,
        customerName: customerName,
        usageLimit: usageLimit,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.savePaymentLink(paymentLink);
      
      // Add to local list
      _paymentLinks.insert(0, paymentLink);
      notifyListeners();
      
      return paymentLink;
    } catch (e) {
      _setError('Failed to create payment link: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Simulate a payment for testing
  Future<Transaction?> simulatePayment(String invoiceId, {String? customerEmail}) async {
    if (_currentMerchant == null) {
      _setError('No merchant selected');
      return null;
    }

    try {
      _setLoading(true);
      
      final transaction = await _transactionService.simulatePayment(
        merchantId: _currentMerchant!.id,
        invoiceId: invoiceId,
        customerEmail: customerEmail,
      );

      // Reload data to reflect changes
      await loadTransactions();
      await loadMerchantInvoices();
      if (customerEmail != null) {
        await loadCustomers();
      }

      return transaction;
    } catch (e) {
      _setError('Failed to simulate payment: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>?> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentMerchant == null) return null;

    try {
      return await _transactionService.getTransactionAnalytics(
        _currentMerchant!.id,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Failed to get analytics: $e');
      return null;
    }
  }

  // Get recent transactions for dashboard
  List<Transaction> get recentTransactions {
    return _transactions.take(5).toList();
  }

  // Get payment statistics
  Map<String, dynamic> get paymentStats {
    final completedTransactions = _transactions.where((t) => t.isCompleted && t.isIncoming).toList();
    final totalRevenue = completedTransactions.fold(0.0, (sum, t) => sum + t.amountNaira);
    final averageTransaction = completedTransactions.isNotEmpty 
        ? totalRevenue / completedTransactions.length 
        : 0.0;

    return {
      'totalTransactions': completedTransactions.length,
      'totalRevenue': totalRevenue,
      'averageTransactionValue': averageTransaction,
      'successRate': _transactions.isNotEmpty 
          ? (completedTransactions.length / _transactions.length * 100)
          : 0.0,
    };
  }

  // Watch for real-time updates
  void subscribeToRealtimeUpdates() {
    if (_currentMerchant == null) return;

    // Subscribe to transaction updates
    _firebaseService.watchMerchantTransactions(_currentMerchant!.id).listen((transactions) {
      _transactions = List<Transaction>.from(transactions);
      notifyListeners();
    });

    // Subscribe to payment link updates
    _firebaseService.watchMerchantPaymentLinks(_currentMerchant!.id).listen((paymentLinks) {
      _paymentLinks = List<PaymentLink>.from(paymentLinks);
      notifyListeners();
    });
  }
}