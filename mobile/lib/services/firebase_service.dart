import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart' as models;

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _merchantsCollection = 'merchants';
  static const String _invoicesCollection = 'invoices';
  static const String _usersCollection = 'users';

  // Helper to get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Merchant Operations
  Future<models.Merchant> saveMerchant(models.Merchant merchant) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore.collection(_merchantsCollection).doc(merchant.id);
      
      await docRef.set({
        ...merchant.toJson(),
        'userId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return merchant with updated timestamp
      return merchant.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to save merchant data: $e');
    }
  }

  Future<models.Merchant?> getMerchant(String merchantId) async {
    try {
      final doc = await _firestore
          .collection(_merchantsCollection)
          .doc(merchantId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return models.Merchant.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load merchant: $e');
    }
  }

  Future<List<models.Merchant>> getUserMerchants() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _firestore
          .collection(_merchantsCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return models.Merchant.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load user merchants: $e');
    }
  }

  Future<models.Merchant> createMerchant({
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
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create merchant with auto-generated ID
      final docRef = _firestore.collection(_merchantsCollection).doc();
      
      final merchant = models.Merchant(
        id: docRef.id,
        userId: currentUserId!,
        businessName: businessName,
        industry: industry,
        contactEmail: contactEmail,
        businessAddress: businessAddress,
        fullName: fullName,
        idNumber: idNumber,
        bvn: bvn,
        address: address,
        kycStatus: 'pending',
        isSetupComplete: _isSetupComplete(
          businessName: businessName,
          industry: industry,
          contactEmail: contactEmail,
          fullName: fullName,
          bankAccountNumber: bankAccountNumber,
          bankName: bankName,
          bankAccountName: bankAccountName,
        ),
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        bankAccountName: bankAccountName,
        walletAddresses: walletAddresses ?? {},
        totalBalance: 0.0,
        availableBalance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set({
        ...merchant.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return merchant;
    } catch (e) {
      throw Exception('Failed to create merchant: $e');
    }
  }

  Future<models.Merchant> updateMerchant(models.Merchant merchant) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore.collection(_merchantsCollection).doc(merchant.id);
      
      final updatedMerchant = merchant.copyWith(updatedAt: DateTime.now());
      
      await docRef.update({
        ...updatedMerchant.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return updatedMerchant;
    } catch (e) {
      throw Exception('Failed to update merchant: $e');
    }
  }

  Future<void> deleteMerchant(String merchantId) async {
    try {
      await _firestore.collection(_merchantsCollection).doc(merchantId).delete();
    } catch (e) {
      throw Exception('Failed to delete merchant: $e');
    }
  }

  // Invoice Operations
  Future<models.Invoice> saveInvoice(models.Invoice invoice) async {
    try {
      final docRef = _firestore.collection(_invoicesCollection).doc(invoice.id);
      
      await docRef.set({
        ...invoice.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return invoice;
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  Future<List<models.Invoice>> getMerchantInvoices(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_invoicesCollection)
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return models.Invoice.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load merchant invoices: $e');
    }
  }

  Future<models.Invoice?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return models.Invoice.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load invoice: $e');
    }
  }

  // User Profile Operations
  Future<void> saveUserProfile({
    required String displayName,
    required String email,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection(_usersCollection).doc(currentUserId).set({
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  // Helper methods
  bool _isSetupComplete({
    required String businessName,
    required String industry,
    required String contactEmail,
    required String fullName,
    required String bankAccountNumber,
    required String bankName,
    required String bankAccountName,
  }) {
    return businessName.isNotEmpty &&
           industry.isNotEmpty &&
           contactEmail.isNotEmpty &&
           fullName.isNotEmpty &&
           bankAccountNumber.isNotEmpty &&
           bankName.isNotEmpty &&
           bankAccountName.isNotEmpty;
  }

  // Stream methods for real-time updates
  Stream<List<models.Merchant>> watchUserMerchants() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_merchantsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return models.Merchant.fromJson(data);
      }).toList();
    });
  }

  Stream<List<models.Invoice>> watchMerchantInvoices(String merchantId) {
    return _firestore
        .collection(_invoicesCollection)
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return models.Invoice.fromJson(data);
      }).toList();
    });
  }

  // Invoice methods
  Future<models.Invoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return models.Invoice.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting invoice: $e');
      return null;
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status, {String? txHash}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (status == 'paid') {
        updateData['paidAt'] = DateTime.now().toIso8601String();
      }
      
      if (txHash != null) {
        updateData['txHash'] = txHash;
      }

      await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .update(updateData);
      
      print('Invoice status updated: $invoiceId -> $status');
    } catch (e) {
      print('Error updating invoice status: $e');
      rethrow;
    }
  }

  // Transaction tracking methods
  Future<void> saveTransaction(models.Transaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());
      print('Transaction saved successfully: ${transaction.id}');
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  Future<List<models.Transaction>> getTransactions(String merchantId, {int? limit, String? lastDocumentId}) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('transactions')
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => models.Transaction.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Stream<List<models.Transaction>> watchMerchantTransactions(String merchantId) {
    return _firestore
        .collection('transactions')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit real-time stream for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> updateTransactionStatus(String transactionId, String status, {String? txHash}) async {
    try {
      final updateData = {
        'status': status,
      };
      
      if (status == 'completed') {
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }
      
      if (txHash != null) {
        updateData['txHash'] = txHash;
      }

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);
      
      print('Transaction status updated: $transactionId -> $status');
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  // Payment links management
  Future<void> savePaymentLink(models.PaymentLink paymentLink) async {
    try {
      await _firestore
          .collection('payment_links')
          .doc(paymentLink.id)
          .set(paymentLink.toJson());
      print('Payment link saved successfully: ${paymentLink.id}');
    } catch (e) {
      print('Error saving payment link: $e');
      rethrow;
    }
  }

  Future<models.PaymentLink?> getPaymentLink(String paymentLinkId) async {
    try {
      final doc = await _firestore
          .collection('payment_links')
          .doc(paymentLinkId)
          .get();

      if (doc.exists) {
        return models.PaymentLink.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting payment link: $e');
      return null;
    }
  }

  Future<List<models.PaymentLink>> getPaymentLinks(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payment_links')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => models.PaymentLink.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting payment links: $e');
      return [];
    }
  }

  Stream<List<models.PaymentLink>> watchMerchantPaymentLinks(String merchantId) {
    return _firestore
        .collection('payment_links')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.PaymentLink.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> updatePaymentLinkUsage(String paymentLinkId, String invoiceId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final paymentLinkRef = _firestore.collection('payment_links').doc(paymentLinkId);
        final paymentLinkDoc = await transaction.get(paymentLinkRef);
        
        if (!paymentLinkDoc.exists) {
          throw Exception('Payment link not found');
        }

        final currentData = paymentLinkDoc.data()!;
        final currentUsageCount = currentData['usageCount'] ?? 0;
        final currentInvoiceIds = List<String>.from(currentData['invoiceIds'] ?? []);
        
        if (!currentInvoiceIds.contains(invoiceId)) {
          currentInvoiceIds.add(invoiceId);
        }

        transaction.update(paymentLinkRef, {
          'usageCount': currentUsageCount + 1,
          'invoiceIds': currentInvoiceIds,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
      
      print('Payment link usage updated: $paymentLinkId');
    } catch (e) {
      print('Error updating payment link usage: $e');
      rethrow;
    }
  }

  // Customer management
  Future<void> saveCustomer(models.Customer customer) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .set(customer.toJson());
      print('Customer saved successfully: ${customer.id}');
    } catch (e) {
      print('Error saving customer: $e');
      rethrow;
    }
  }

  Future<models.Customer?> getCustomerByEmail(String merchantId, String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('merchantId', isEqualTo: merchantId)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return models.Customer.fromJson({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting customer by email: $e');
      return null;
    }
  }

  Future<List<models.Customer>> getCustomers(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('totalSpentNaira', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => models.Customer.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting customers: $e');
      return [];
    }
  }

  Future<void> updateCustomerStats(String customerId, double transactionAmount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final customerRef = _firestore.collection('customers').doc(customerId);
        final customerDoc = await transaction.get(customerRef);
        
        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final currentData = customerDoc.data()!;
        final currentTransactions = currentData['totalTransactions'] ?? 0;
        final currentSpent = (currentData['totalSpentNaira'] ?? 0.0).toDouble();

        transaction.update(customerRef, {
          'totalTransactions': currentTransactions + 1,
          'totalSpentNaira': currentSpent + transactionAmount,
          'lastTransactionAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
      
      print('Customer stats updated: $customerId');
    } catch (e) {
      print('Error updating customer stats: $e');
      rethrow;
    }
  }

  // Analytics methods for real transaction data
  Future<Map<String, dynamic>> getMerchantAnalytics(String merchantId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query transactionQuery = _firestore
          .collection('transactions')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed');

      if (startDate != null) {
        transactionQuery = transactionQuery.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      
      if (endDate != null) {
        transactionQuery = transactionQuery.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final transactionSnapshot = await transactionQuery.get();
      final transactions = transactionSnapshot.docs
          .map((doc) => models.Transaction.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // Calculate analytics
      final totalRevenue = transactions
          .where((t) => t.type == 'payment_received')
          .fold<double>(0.0, (sum, t) => sum + t.amountNaira);
      
      final totalTransactions = transactions.length;
      
      final successfulTransactions = transactions
          .where((t) => t.status == 'completed')
          .length;
      
      final successRate = totalTransactions > 0 ? (successfulTransactions / totalTransactions * 100) : 0.0;

      final averageTransactionValue = totalTransactions > 0 
          ? totalRevenue / totalTransactions 
          : 0.0;

      // Group by day for chart data
      final Map<String, double> dailyRevenue = {};
      for (final transaction in transactions) {
        if (transaction.type == 'payment_received') {
          final day = transaction.createdAt.toIso8601String().split('T')[0];
          dailyRevenue[day] = (dailyRevenue[day] ?? 0.0) + transaction.amountNaira;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalTransactions': totalTransactions,
        'successRate': successRate,
        'averageTransactionValue': averageTransactionValue,
        'dailyRevenue': dailyRevenue,
        'recentTransactions': transactions.take(10).map((t) => t.toJson()).toList(),
      };
    } catch (e) {
      print('Error getting merchant analytics: $e');
      return {
        'totalRevenue': 0.0,
        'totalTransactions': 0,
        'successRate': 0.0,
        'averageTransactionValue': 0.0,
        'dailyRevenue': <String, double>{},
        'recentTransactions': <Map<String, dynamic>>[],
      };
    }
  }
}
