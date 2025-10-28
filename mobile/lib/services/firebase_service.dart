import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../models/models.dart' as models;
import '../utils/app_logger.dart';
import 'crypto_wallet_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _functionsBaseUrl;

  // Collections
  static const String _merchantsCollection = 'merchants';
  static const String _invoicesCollection = 'invoices';
  static const String _usersCollection = 'users';

  // Helper to get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get the current Firebase ID token for the logged-in user, or null if not available.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken(forceRefresh);
      return token;
    } catch (e) {
      AppLogger.e('Error getting ID token: $e', error: e);
      return null;
    }
  }

  // Merchant Operations
  Future<models.Merchant> saveMerchant(models.Merchant merchant) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore.collection(_merchantsCollection).doc(merchant.id);
      
      final data = {
        ...merchant.toJson(),
        'userId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If wallet addresses are present, mark walletsGenerated for backend compatibility
      if ((merchant.walletAddresses?.isNotEmpty ?? false)) {
        data['walletsGenerated'] = true;
        data['walletsGeneratedAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data);

      // Return merchant with updated timestamp
      return merchant.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to save merchant data: $e');
    }
  }

  // Client-side helper to fetch tier configs
  Future<Map<String, dynamic>> _fetchTierConfigsClient() async {
    try {
      final snap = await _firestore.collection('config_merchantTiers').get();
      final map = <String, dynamic>{};
      for (final d in snap.docs) {
        map[d.id] = d.data();
      }
      return map;
    } catch (e) {
      AppLogger.w('Failed to fetch tier configs client-side: $e');
      return {};
    }
  }

  Future<double> _sumCompletedPaymentsClient(String merchantId, {DateTime? start, DateTime? end}) async {
    try {
      Query q = _firestore.collection('payments').where('merchantId', isEqualTo: merchantId).where('status', isEqualTo: 'completed');
      if (start != null) q = q.where('createdAt', isGreaterThanOrEqualTo: start);
      if (end != null) q = q.where('createdAt', isLessThanOrEqualTo: end);
      final snap = await q.get();
      double total = 0.0;
      for (final d in snap.docs) {
        final data = d.data();
        total += (data['amountNgn'] ?? data['amount'] ?? 0);
      }
      return total;
    } catch (e) {
      AppLogger.w('Failed to sum completed payments client-side: $e');
      return 0.0;
    }
  }

  Future<void> _enforceTierLimitsClient(String merchantId, double? requestedAmount) async {
    final merchantDoc = await _firestore.collection(_merchantsCollection).doc(merchantId).get();
    if (!merchantDoc.exists) throw Exception('Merchant not found');
    final merchant = merchantDoc.data()!;
    final tierId = merchant['merchantTier'] ?? 'Tier0_Unregistered';

    final configs = await _fetchTierConfigsClient();
    final tier = configs[tierId] ?? null;

    if (tier == null) return; // no client-side enforcement if no config

    if (requestedAmount != null && tier['singleLimit'] != null && requestedAmount > (tier['singleLimit'] as num)) {
      throw Exception('Requested amount exceeds single-transaction limit for your tier.');
    }

    if (tier['dailyLimit'] != null) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final dayTotal = await _sumCompletedPaymentsClient(merchantId, start: startOfDay);
      if (requestedAmount != null && (dayTotal + requestedAmount) > (tier['dailyLimit'] as num)) {
        throw Exception('Daily limit exceeded for your tier.');
      }
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
    String? merchantTier,
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
        merchantTier: merchantTier ?? 'Tier0_Unregistered',
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

      final data = {
        ...merchant.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if ((walletAddresses?.isNotEmpty ?? false)) {
        data['walletsGenerated'] = true;
        data['walletsGeneratedAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data);

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

      final data = {
        ...updatedMerchant.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If wallet addresses exist, ensure backend flag is set
      if ((updatedMerchant.walletAddresses?.isNotEmpty ?? false)) {
        data['walletsGenerated'] = true;
        data['walletsGeneratedAt'] = FieldValue.serverTimestamp();
      } else {
        data['walletsGenerated'] = false;
      }

      await docRef.update(data);

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
    bool isTest = false,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isTest) {
        data['isTest'] = true;
      }

      await _firestore.collection(_usersCollection).doc(currentUserId).set(data, SetOptions(merge: true));
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

  // Admin helper: get user by id (for auth provider role resolution)
  Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      AppLogger.e('Error fetching user by id: $e', error: e);
      return null;
    }
  }

  // Admin: list merchants that require KYC review
  Future<List<models.Merchant>> getMerchantsForKycReview({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_merchantsCollection)
          .where('kycStatus', whereIn: ['pending', 'under-review'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return models.Merchant.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching merchants for KYC review: $e', error: e);
      return [];
    }
  }

  // Admin: update merchant kyc status
  Future<void> updateMerchantKycStatus(String merchantId, String newStatus, {String? reason}) async {
    // If a cloud function base URL is configured, prefer invoking the callable function
    if (_functionsBaseUrl != null) {
      try {
        final idToken = await _auth.currentUser?.getIdToken();
        if (idToken != null) {
          final url = Uri.parse('${_functionsBaseUrl!.replaceAll(RegExp(r'/*$'), '')}/updateMerchantKyc');
          final resp = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'merchantId': merchantId, 'newStatus': newStatus, 'reason': reason}),
          );

          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            // success; function already writes audit logs server-side
            return;
          } else {
            AppLogger.e('Functions call failed (${resp.statusCode}): ${resp.body}');
            // fallthrough to direct update
          }
        }
      } catch (fnError) {
        AppLogger.e('Error calling functions endpoint: $fnError', error: fnError);
        // continue to fallback
      }
    }

    // Fallback: direct Firestore update and client-side audit log
    try {
      await _firestore.collection(_merchantsCollection).doc(merchantId).update({
        'kycStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Audit log: record who changed the status and when
      try {
        final audit = {
          'merchantId': merchantId,
          'newStatus': newStatus,
          'reason': reason ?? '',
          'changedBy': currentUserId ?? 'unknown',
          'changedAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('admin_audit_logs').add(audit);
      } catch (auditError) {
        AppLogger.e('Failed to write admin audit log: $auditError', error: auditError);
      }

      AppLogger.d('Merchant $merchantId KYC status updated to $newStatus');
    } catch (e) {
      AppLogger.e('Error updating merchant KYC status: $e', error: e);
      rethrow;
    }
  }

  /// Configure a base URL for callable Cloud Functions (e.g. https://us-central1-<proj>.cloudfunctions.net)
  void setFunctionsBaseUrl(String baseUrl) {
    _functionsBaseUrl = baseUrl;
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

  // Upload a KYC document (image/pdf) to Firebase Storage under 'kyc/{merchantId}/'
  // and create a metadata record in Firestore under merchants/{merchantId}/documents.
  // Enforces a 5MB size limit.
  Future<Map<String, dynamic>> uploadKycDocument(String merchantId, PlatformFile file, {required String docType}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Size check: file.size is in bytes
    const int maxBytes = 5 * 1024 * 1024; // 5MB
    if (file.size > maxBytes) {
      throw Exception('File exceeds maximum allowed size of 5MB');
    }

    try {
      final storage = FirebaseStorage.instance;
      final filename = '${DateTime.now().toUtc().toIso8601String()}_${path.basename(file.name)}';
      final storagePath = 'kyc/${merchantId}/${filename}';

      final ref = storage.ref().child(storagePath);

      UploadTask uploadTask;

      // If we have a path on the PlatformFile, upload from file.
      if (file.path != null) {
        final fileToUpload = File(file.path!);
        final metadata = SettableMetadata(
          contentType: file.extension != null && file.extension!.toLowerCase() == 'pdf' ? 'application/pdf' : 'image/jpeg',
        );

        uploadTask = ref.putFile(fileToUpload, metadata);
      } else if (file.bytes != null) {
        final metadata = SettableMetadata(
          contentType: file.extension != null && file.extension!.toLowerCase() == 'pdf' ? 'application/pdf' : 'image/jpeg',
        );
        uploadTask = ref.putData(file.bytes!, metadata);
      } else {
        throw Exception('No file data available to upload');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final docData = {
        'filename': file.name,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'contentType': file.extension != null && file.extension!.toLowerCase() == 'pdf' ? 'application/pdf' : 'image/jpeg',
        'size': file.size,
        'uploadedBy': currentUserId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'docType': docType,
      };

      // Write metadata under merchants/{merchantId}/documents
      final docRef = _firestore.collection('merchants').doc(merchantId).collection('documents').doc();
      await docRef.set(docData);

      // Return record including generated id
      return {'id': docRef.id, ...docData};
    } catch (e) {
      AppLogger.e('Failed to upload KYC document: $e', error: e);
      rethrow;
    }
  }

  /// Fetch list of KYC documents metadata saved under merchants/{merchantId}/documents
  Future<List<Map<String, dynamic>>> getMerchantDocuments(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('documents')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((d) {
        final m = d.data();
        m['id'] = d.id;
        return m;
      }).toList();
    } catch (e) {
      AppLogger.e('Error fetching merchant documents: $e', error: e);
      return [];
    }
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

  /// Ensure wallet documents exist in the 'wallets' collection for a merchant.
  /// Uses deterministic document ids of the form '<merchantId>_<network>' so
  /// repeated calls are idempotent.
  Future<void> upsertMerchantWallets(String merchantId, Map<String, String> walletAddresses) async {
    try {
      final batch = _firestore.batch();

      AppLogger.d('DEBUG: Preparing to upsert ${walletAddresses.length} wallets for merchant $merchantId');
      walletAddresses.forEach((network, address) {
        final docId = '${merchantId}_${network.toLowerCase()}';
        final docRef = _firestore.collection('wallets').doc(docId);
        AppLogger.d('DEBUG: Upserting wallet doc $docId -> $address');
        batch.set(docRef, {
          'merchantId': merchantId,
          'chain': network,
          'publicAddress': address,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      await batch.commit();
      AppLogger.d('DEBUG: Upserted ${walletAddresses.length} wallet documents for merchant $merchantId');
    } catch (e) {
      AppLogger.e('Failed to upsert merchant wallets: $e', error: e);
      rethrow;
    }
  }

  /// Generate deterministic wallet addresses for a merchant and persist them.
  /// Returns the generated map of network->address.
  Future<Map<String, String>> generateAndSaveMerchantWallets(String merchantId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate addresses deterministically
      final wallets = CryptoWalletService.generateWalletAddresses(merchantId: merchantId, userId: userId);

      // Save wallet addresses on merchant document and mark walletsGenerated
      final merchantRef = _firestore.collection(_merchantsCollection).doc(merchantId);
      await merchantRef.set({
        'walletAddresses': wallets,
        'walletsGenerated': true,
        'walletsGeneratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Upsert per-network wallet docs
      await upsertMerchantWallets(merchantId, wallets);

      AppLogger.d('DEBUG: Generated and saved ${wallets.length} wallets for merchant $merchantId');
      return wallets;
    } catch (e) {
      AppLogger.e('Failed to generate and save merchant wallets: $e', error: e);
      rethrow;
    }
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
      AppLogger.e('Error getting invoice: $e', error: e);
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
      
      AppLogger.d('Invoice status updated: $invoiceId -> $status');
    } catch (e) {
      AppLogger.e('Error updating invoice status: $e', error: e);
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
      AppLogger.d('Transaction saved successfully: ${transaction.id}');
    } catch (e) {
      AppLogger.e('Error saving transaction: $e', error: e);
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
      AppLogger.e('Error getting transactions: $e', error: e);
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
      
      AppLogger.d('Transaction status updated: $transactionId -> $status');
    } catch (e) {
      AppLogger.e('Error updating transaction status: $e', error: e);
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
      AppLogger.d('Payment link saved successfully: ${paymentLink.id}');
    } catch (e) {
      AppLogger.e('Error saving payment link: $e', error: e);
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
      AppLogger.e('Error getting payment link: $e', error: e);
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
      AppLogger.e('Error getting payment links: $e', error: e);
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
      
      AppLogger.d('Payment link usage updated: $paymentLinkId');
    } catch (e) {
      AppLogger.e('Error updating payment link usage: $e', error: e);
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
      AppLogger.d('Customer saved successfully: ${customer.id}');
    } catch (e) {
      AppLogger.e('Error saving customer: $e', error: e);
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
      AppLogger.e('Error getting customer by email: $e', error: e);
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
      AppLogger.e('Error getting customers: $e', error: e);
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
      
      AppLogger.d('Customer stats updated: $customerId');
    } catch (e) {
      AppLogger.e('Error updating customer stats: $e', error: e);
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
      AppLogger.e('Error getting merchant analytics: $e', error: e);
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

  /// Save a receipt record for merchant/transaction. `id` should be unique (e.g. 'receipt_<txId>').
  Future<void> saveReceipt(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('receipts').doc(id).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      AppLogger.d('Receipt saved: $id');
    } catch (e) {
      AppLogger.e('Error saving receipt $id: $e', error: e);
      rethrow;
    }
  }
}
