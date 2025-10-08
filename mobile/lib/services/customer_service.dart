import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Customer CRUD Operations
  Future<List<Customer>> getCustomers(String merchantId, {
    int limit = 50,
    String? searchQuery,
    String? status,
    String? tier,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('customers')
          .where('merchantId', isEqualTo: merchantId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (tier != null) {
        query = query.where('tier', isEqualTo: tier);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      query = query.orderBy('updatedAt', descending: true).limit(limit);

      final querySnapshot = await query.get();
      List<Customer> customers = querySnapshot.docs
          .map((doc) => Customer.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply additional filters that can't be done in Firestore
      if (searchQuery != null && searchQuery.isNotEmpty) {
        customers = customers.where((customer) =>
          customer.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          customer.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (customer.phone?.contains(searchQuery) ?? false)
        ).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        customers = customers.where((customer) =>
          customer.tags.any((tag) => tags.contains(tag))
        ).toList();
      }

      return customers;
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      return [];
    }
  }

  Future<Customer?> getCustomer(String customerId) async {
    try {
      final doc = await _firestore.collection('customers').doc(customerId).get();
      
      if (doc.exists && doc.data() != null) {
        return Customer.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching customer: $e');
      return null;
    }
  }

  Future<Customer?> getCustomerByEmail(String merchantId, String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('merchantId', isEqualTo: merchantId)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Customer.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching customer by email: $e');
      return null;
    }
  }

  Future<String> createCustomer(Customer customer) async {
    try {
      final customerRef = _firestore.collection('customers').doc();
      final newCustomer = customer.copyWith(
        id: customerRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await customerRef.set(newCustomer.toJson());
      return customerRef.id;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .update(updatedCustomer.toJson());
    } catch (e) {
      debugPrint('Error updating customer: $e');
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();
      
      // Also delete related data
      await _deleteCustomerData(customerId);
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      throw Exception('Failed to delete customer: $e');
    }
  }

  Future<void> _deleteCustomerData(String customerId) async {
    try {
      // Delete customer interactions
      final interactionsQuery = await _firestore
          .collection('customer_interactions')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in interactionsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete customer notes
      final notesQuery = await _firestore
          .collection('customer_notes')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in notesQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting customer data: $e');
    }
  }

  // Customer Statistics and Analytics
  Future<Map<String, dynamic>> getCustomerStatistics(String merchantId) async {
    try {
      final customers = await getCustomers(merchantId, limit: 1000);
      
      final stats = {
        'totalCustomers': customers.length,
        'activeCustomers': customers.where((c) => c.status == 'active').length,
        'inactiveCustomers': customers.where((c) => c.status == 'inactive').length,
        'vipCustomers': customers.where((c) => c.isVIP).length,
        'returningCustomers': customers.where((c) => c.isReturning).length,
        'newCustomersThisMonth': customers.where((c) => 
          c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).length,
        'totalRevenue': customers.fold<double>(0, (sum, c) => sum + c.totalSpentNaira),
        'averageSpending': customers.isNotEmpty 
          ? customers.fold<double>(0, (sum, c) => sum + c.totalSpentNaira) / customers.length
          : 0,
        'tierDistribution': {
          'bronze': customers.where((c) => c.tier == 'bronze').length,
          'silver': customers.where((c) => c.tier == 'silver').length,
          'gold': customers.where((c) => c.tier == 'gold').length,
          'platinum': customers.where((c) => c.tier == 'platinum').length,
        },
        'engagementLevels': {
          'highly_active': customers.where((c) => c.engagementLevel == 'Highly Active').length,
          'active': customers.where((c) => c.engagementLevel == 'Active').length,
          'moderate': customers.where((c) => c.engagementLevel == 'Moderate').length,
          'inactive': customers.where((c) => c.engagementLevel == 'Inactive').length,
          'dormant': customers.where((c) => c.engagementLevel == 'Dormant').length,
        },
        'customersNeedingAttention': customers.where((c) => c.requiresAttention).length,
      };

      return stats;
    } catch (e) {
      debugPrint('Error getting customer statistics: $e');
      return {};
    }
  }

  // Customer Interactions
  Future<List<CustomerInteraction>> getCustomerInteractions(
    String customerId, {
    int limit = 50,
    String? type,
  }) async {
    try {
      Query query = _firestore
          .collection('customer_interactions')
          .where('customerId', isEqualTo: customerId);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => CustomerInteraction.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching customer interactions: $e');
      return [];
    }
  }

  Future<String> createInteraction(CustomerInteraction interaction) async {
    try {
      final interactionRef = _firestore.collection('customer_interactions').doc();
      final newInteraction = interaction.copyWith(
        id: interactionRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await interactionRef.set(newInteraction.toJson());
      return interactionRef.id;
    } catch (e) {
      debugPrint('Error creating interaction: $e');
      throw Exception('Failed to create interaction: $e');
    }
  }

  Future<void> updateInteraction(CustomerInteraction interaction) async {
    try {
      final updatedInteraction = interaction.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('customer_interactions')
          .doc(interaction.id)
          .update(updatedInteraction.toJson());
    } catch (e) {
      debugPrint('Error updating interaction: $e');
      throw Exception('Failed to update interaction: $e');
    }
  }

  // Customer Notes
  Future<List<CustomerNote>> getCustomerNotes(
    String customerId, {
    bool includePrivate = true,
    String? type,
  }) async {
    try {
      Query query = _firestore
          .collection('customer_notes')
          .where('customerId', isEqualTo: customerId);

      if (!includePrivate) {
        query = query.where('isPrivate', isEqualTo: false);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => CustomerNote.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching customer notes: $e');
      return [];
    }
  }

  Future<String> createNote(CustomerNote note) async {
    try {
      final noteRef = _firestore.collection('customer_notes').doc();
      final newNote = note.copyWith(
        id: noteRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await noteRef.set(newNote.toJson());
      return noteRef.id;
    } catch (e) {
      debugPrint('Error creating note: $e');
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> updateNote(CustomerNote note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('customer_notes')
          .doc(note.id)
          .update(updatedNote.toJson());
    } catch (e) {
      debugPrint('Error updating note: $e');
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('customer_notes').doc(noteId).delete();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }

  // Customer Segmentation
  Future<List<CustomerSegment>> getCustomerSegments(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('customer_segments')
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CustomerSegment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching customer segments: $e');
      return [];
    }
  }

  Future<String> createSegment(CustomerSegment segment) async {
    try {
      final segmentRef = _firestore.collection('customer_segments').doc();
      final newSegment = segment.copyWith(
        id: segmentRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await segmentRef.set(newSegment.toJson());
      return segmentRef.id;
    } catch (e) {
      debugPrint('Error creating segment: $e');
      throw Exception('Failed to create segment: $e');
    }
  }

  Future<List<Customer>> getCustomersBySegment(String segmentId) async {
    try {
      final segment = await _firestore
          .collection('customer_segments')
          .doc(segmentId)
          .get();

      if (!segment.exists) return [];

      final segmentData = CustomerSegment.fromJson(segment.data()!);
      
      if (segmentData.type == 'static') {
        // Get customers by IDs
        if (segmentData.customerIds.isEmpty) return [];
        
        final customers = <Customer>[];
        for (final customerId in segmentData.customerIds) {
          final customer = await getCustomer(customerId);
          if (customer != null) customers.add(customer);
        }
        return customers;
      } else {
        // Dynamic segment - apply criteria
        return await _applySegmentCriteria(segmentData);
      }
    } catch (e) {
      debugPrint('Error getting customers by segment: $e');
      return [];
    }
  }

  Future<List<Customer>> _applySegmentCriteria(CustomerSegment segment) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd have more sophisticated criteria matching
      final allCustomers = await getCustomers(segment.merchantId, limit: 1000);
      
      return allCustomers.where((customer) {
        // Apply segment criteria
        final criteria = segment.criteria;
        
        if (criteria.containsKey('tier') && criteria['tier'] != customer.tier) {
          return false;
        }
        
        if (criteria.containsKey('status') && criteria['status'] != customer.status) {
          return false;
        }
        
        if (criteria.containsKey('minSpending')) {
          final minSpending = (criteria['minSpending'] as num).toDouble();
          if (customer.totalSpentNaira < minSpending) return false;
        }
        
        if (criteria.containsKey('minTransactions')) {
          final minTransactions = criteria['minTransactions'] as int;
          if (customer.totalTransactions < minTransactions) return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error applying segment criteria: $e');
      return [];
    }
  }

  // Bulk Operations
  Future<void> updateCustomerTiers(String merchantId) async {
    try {
      final customers = await getCustomers(merchantId, limit: 1000);
      
      for (final customer in customers) {
        String newTier = 'bronze';
        
        if (customer.totalSpentNaira >= 1000000) {
          newTier = 'platinum';
        } else if (customer.totalSpentNaira >= 500000) {
          newTier = 'gold';
        } else if (customer.totalSpentNaira >= 100000) {
          newTier = 'silver';
        }
        
        if (newTier != customer.tier) {
          await updateCustomer(customer.copyWith(tier: newTier));
        }
      }
    } catch (e) {
      debugPrint('Error updating customer tiers: $e');
    }
  }

  Future<void> bulkUpdateCustomers(
    List<String> customerIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final customerId in customerIds) {
        final customerRef = _firestore.collection('customers').doc(customerId);
        batch.update(customerRef, {
          ...updates,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error bulk updating customers: $e');
      throw Exception('Failed to bulk update customers: $e');
    }
  }

  // Search and Filter Helpers
  Future<List<Customer>> searchCustomers(
    String merchantId,
    String searchQuery, {
    int limit = 50,
  }) async {
    try {
      // Get all customers and filter locally for better search
      final customers = await getCustomers(merchantId, limit: 200);
      
      final query = searchQuery.toLowerCase();
      return customers.where((customer) =>
        customer.displayName.toLowerCase().contains(query) ||
        customer.email.toLowerCase().contains(query) ||
        (customer.phone?.contains(query) ?? false) ||
        customer.tags.any((tag) => tag.toLowerCase().contains(query))
      ).take(limit).toList();
    } catch (e) {
      debugPrint('Error searching customers: $e');
      return [];
    }
  }

  Future<List<Customer>> getCustomersNeedingAttention(String merchantId) async {
    try {
      final customers = await getCustomers(merchantId, limit: 1000);
      return customers.where((customer) => customer.requiresAttention).toList();
    } catch (e) {
      debugPrint('Error getting customers needing attention: $e');
      return [];
    }
  }

  Future<List<Customer>> getTopCustomers(
    String merchantId, {
    int limit = 10,
    String sortBy = 'totalSpent',
  }) async {
    try {
      final customers = await getCustomers(merchantId, limit: 1000);
      
      customers.sort((a, b) {
        switch (sortBy) {
          case 'totalTransactions':
            return b.totalTransactions.compareTo(a.totalTransactions);
          case 'recentActivity':
            final aLastTransaction = a.lastTransactionAt ?? DateTime(2000);
            final bLastTransaction = b.lastTransactionAt ?? DateTime(2000);
            return bLastTransaction.compareTo(aLastTransaction);
          default: // totalSpent
            return b.totalSpentNaira.compareTo(a.totalSpentNaira);
        }
      });
      
      return customers.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top customers: $e');
      return [];
    }
  }

  Future<void> deleteCustomerSegment(String merchantId, String segmentId) async {
    try {
      await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('customerSegments')
          .doc(segmentId)
          .delete();
      debugPrint('Customer segment deleted successfully: $segmentId');
    } catch (e) {
      debugPrint('Error deleting customer segment: $e');
      throw Exception('Failed to delete customer segment: $e');
    }
  }
}