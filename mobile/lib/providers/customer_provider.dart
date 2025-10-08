import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();

  // State variables
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<CustomerInteraction> _customerInteractions = [];
  List<CustomerNote> _customerNotes = [];
  List<CustomerSegment> _customerSegments = [];
  Map<String, dynamic> _customerStatistics = {};

  // Loading states
  bool _isLoadingCustomers = false;
  bool _isLoadingCustomer = false;
  bool _isLoadingInteractions = false;
  bool _isLoadingNotes = false;
  bool _isLoadingSegments = false;
  bool _isLoadingStatistics = false;

  // Filter and search states
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedTier;
  List<String> _selectedTags = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'updatedAt';
  bool _sortDescending = true;

  // Getters
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<CustomerInteraction> get customerInteractions => _customerInteractions;
  List<CustomerNote> get customerNotes => _customerNotes;
  List<CustomerSegment> get customerSegments => _customerSegments;
  Map<String, dynamic> get customerStatistics => _customerStatistics;

  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isLoadingCustomer => _isLoadingCustomer;
  bool get isLoadingInteractions => _isLoadingInteractions;
  bool get isLoadingNotes => _isLoadingNotes;
  bool get isLoadingSegments => _isLoadingSegments;
  bool get isLoadingStatistics => _isLoadingStatistics;

  String get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  String? get selectedTier => _selectedTier;
  List<String> get selectedTags => _selectedTags;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get sortBy => _sortBy;
  bool get sortDescending => _sortDescending;

  // Computed properties
  List<Customer> get filteredCustomers {
    List<Customer> filtered = List.from(_customers);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) =>
        customer.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (customer.phone?.contains(_searchQuery) ?? false)
      ).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((customer) => customer.status == _selectedStatus).toList();
    }

    // Apply tier filter
    if (_selectedTier != null) {
      filtered = filtered.where((customer) => customer.tier == _selectedTier).toList();
    }

    // Apply tags filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((customer) =>
        customer.tags.any((tag) => _selectedTags.contains(tag))
      ).toList();
    }

    // Apply date filters
    if (_startDate != null) {
      filtered = filtered.where((customer) => 
        customer.createdAt.isAfter(_startDate!)
      ).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((customer) => 
        customer.createdAt.isBefore(_endDate!)
      ).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (_sortBy) {
        case 'name':
          aValue = a.displayName;
          bValue = b.displayName;
          break;
        case 'email':
          aValue = a.email;
          bValue = b.email;
          break;
        case 'totalSpent':
          aValue = a.totalSpentNaira;
          bValue = b.totalSpentNaira;
          break;
        case 'totalTransactions':
          aValue = a.totalTransactions;
          bValue = b.totalTransactions;
          break;
        case 'lastTransaction':
          aValue = a.lastTransactionAt ?? DateTime(2000);
          bValue = b.lastTransactionAt ?? DateTime(2000);
          break;
        case 'tier':
          aValue = a.tier;
          bValue = b.tier;
          break;
        case 'status':
          aValue = a.status;
          bValue = b.status;
          break;
        default: // updatedAt
          aValue = a.updatedAt;
          bValue = b.updatedAt;
      }

      int comparison = 0;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      }

      return _sortDescending ? -comparison : comparison;
    });

    return filtered;
  }

  List<Customer> get activeCustomers => _customers.where((c) => c.isActive).toList();
  List<Customer> get vipCustomers => _customers.where((c) => c.isVIP).toList();
  List<Customer> get returningCustomers => _customers.where((c) => c.isReturning).toList();
  List<Customer> get customersNeedingAttention => _customers.where((c) => c.requiresAttention).toList();

  int get totalCustomers => _customers.length;
  int get activeCustomersCount => activeCustomers.length;
  int get vipCustomersCount => vipCustomers.length;
  int get returningCustomersCount => returningCustomers.length;
  int get customersNeedingAttentionCount => customersNeedingAttention.length;

  // Customer Management Methods
  Future<void> loadCustomers(String merchantId, {bool forceRefresh = false}) async {
    if (_isLoadingCustomers && !forceRefresh) return;

    _isLoadingCustomers = true;
    notifyListeners();

    try {
      _customers = await _customerService.getCustomers(
        merchantId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatus,
        tier: _selectedTier,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      debugPrint('Error loading customers: $e');
      _customers = [];
    }

    _isLoadingCustomers = false;
    notifyListeners();
  }

  Future<void> loadCustomer(String customerId) async {
    if (_isLoadingCustomer) return;

    _isLoadingCustomer = true;
    notifyListeners();

    try {
      _selectedCustomer = await _customerService.getCustomer(customerId);
    } catch (e) {
      debugPrint('Error loading customer: $e');
      _selectedCustomer = null;
    }

    _isLoadingCustomer = false;
    notifyListeners();
  }

  Future<void> createCustomer(Customer customer) async {
    try {
      final customerId = await _customerService.createCustomer(customer);
      final newCustomer = customer.copyWith(id: customerId);
      
      _customers.insert(0, newCustomer);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(String merchantId, Customer customer) async {
    try {
      await _customerService.updateCustomer(customer);
      
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
      }
      
      if (_selectedCustomer?.id == customer.id) {
        _selectedCustomer = customer;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _customerService.deleteCustomer(customerId);
      
      _customers.removeWhere((c) => c.id == customerId);
      
      if (_selectedCustomer?.id == customerId) {
        _selectedCustomer = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      rethrow;
    }
  }

  // Customer Interactions
  Future<void> loadCustomerInteractions(String customerId, {String? type}) async {
    if (_isLoadingInteractions) return;

    _isLoadingInteractions = true;
    notifyListeners();

    try {
      _customerInteractions = await _customerService.getCustomerInteractions(
        customerId,
        type: type,
      );
    } catch (e) {
      debugPrint('Error loading customer interactions: $e');
      _customerInteractions = [];
    }

    _isLoadingInteractions = false;
    notifyListeners();
  }

  Future<void> createInteraction(CustomerInteraction interaction) async {
    try {
      final interactionId = await _customerService.createInteraction(interaction);
      final newInteraction = interaction.copyWith(id: interactionId);
      
      _customerInteractions.insert(0, newInteraction);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating interaction: $e');
      rethrow;
    }
  }

  Future<void> updateInteraction(CustomerInteraction interaction) async {
    try {
      await _customerService.updateInteraction(interaction);
      
      final index = _customerInteractions.indexWhere((i) => i.id == interaction.id);
      if (index != -1) {
        _customerInteractions[index] = interaction;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating interaction: $e');
      rethrow;
    }
  }

  // Customer Notes
  Future<void> loadCustomerNotes(String customerId, {String? type}) async {
    if (_isLoadingNotes) return;

    _isLoadingNotes = true;
    notifyListeners();

    try {
      _customerNotes = await _customerService.getCustomerNotes(
        customerId,
        type: type,
      );
    } catch (e) {
      debugPrint('Error loading customer notes: $e');
      _customerNotes = [];
    }

    _isLoadingNotes = false;
    notifyListeners();
  }

  Future<void> createNote(CustomerNote note) async {
    try {
      final noteId = await _customerService.createNote(note);
      final newNote = note.copyWith(id: noteId);
      
      _customerNotes.insert(0, newNote);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  Future<void> updateNote(CustomerNote note) async {
    try {
      await _customerService.updateNote(note);
      
      final index = _customerNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _customerNotes[index] = note;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _customerService.deleteNote(noteId);
      
      _customerNotes.removeWhere((n) => n.id == noteId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  // Customer Segments
  Future<void> loadCustomerSegments(String merchantId) async {
    if (_isLoadingSegments) return;

    _isLoadingSegments = true;
    notifyListeners();

    try {
      _customerSegments = await _customerService.getCustomerSegments(merchantId);
    } catch (e) {
      debugPrint('Error loading customer segments: $e');
      _customerSegments = [];
    }

    _isLoadingSegments = false;
    notifyListeners();
  }

  Future<void> createSegment(CustomerSegment segment) async {
    try {
      final segmentId = await _customerService.createSegment(segment);
      final newSegment = segment.copyWith(id: segmentId);
      
      _customerSegments.add(newSegment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating segment: $e');
      rethrow;
    }
  }

  // Statistics
  Future<void> loadCustomerStatistics(String merchantId) async {
    if (_isLoadingStatistics) return;

    _isLoadingStatistics = true;
    notifyListeners();

    try {
      _customerStatistics = await _customerService.getCustomerStatistics(merchantId);
    } catch (e) {
      debugPrint('Error loading customer statistics: $e');
      _customerStatistics = {};
    }

    _isLoadingStatistics = false;
    notifyListeners();
  }

  // Filter and Search Methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setTierFilter(String? tier) {
    _selectedTier = tier;
    notifyListeners();
  }

  void setTagsFilter(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setSorting(String sortBy, {bool? descending}) {
    _sortBy = sortBy;
    if (descending != null) {
      _sortDescending = descending;
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedTier = null;
    _selectedTags = [];
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Utility Methods
  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    
    // Load related data when customer is selected
    if (customer != null) {
      loadCustomerInteractions(customer.id);
      loadCustomerNotes(customer.id);
    }
    
    notifyListeners();
  }

  void clearSelection() {
    _selectedCustomer = null;
    _customerInteractions = [];
    _customerNotes = [];
    notifyListeners();
  }

  Future<void> refreshAllData(String merchantId) async {
    await Future.wait([
      loadCustomers(merchantId, forceRefresh: true),
      loadCustomerSegments(merchantId),
      loadCustomerStatistics(merchantId),
    ]);
  }

  // Bulk Operations
  Future<void> bulkUpdateCustomers(
    List<String> customerIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _customerService.bulkUpdateCustomers(customerIds, updates);
      
      // Update local data
      for (final customerId in customerIds) {
        final index = _customers.indexWhere((c) => c.id == customerId);
        if (index != -1) {
          final updatedCustomer = _customers[index].copyWith(
            status: updates['status'],
            tier: updates['tier'],
            tags: updates['tags'],
            updatedAt: DateTime.now(),
          );
          _customers[index] = updatedCustomer;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error bulk updating customers: $e');
      rethrow;
    }
  }

  // Search helpers
  Future<List<Customer>> searchCustomers(String merchantId, String query) async {
    try {
      return await _customerService.searchCustomers(merchantId, query);
    } catch (e) {
      debugPrint('Error searching customers: $e');
      return [];
    }
  }

  Future<List<Customer>> getTopCustomers(
    String merchantId, {
    int limit = 10,
    String sortBy = 'totalSpent',
  }) async {
    try {
      return await _customerService.getTopCustomers(
        merchantId,
        limit: limit,
        sortBy: sortBy,
      );
    } catch (e) {
      debugPrint('Error getting top customers: $e');
      return [];
    }
  }

  // Analytics helpers
  Map<String, int> getTierDistribution() {
    final distribution = <String, int>{
      'bronze': 0,
      'silver': 0,
      'gold': 0,
      'platinum': 0,
    };

    for (final customer in _customers) {
      distribution[customer.tier] = (distribution[customer.tier] ?? 0) + 1;
    }

    return distribution;
  }

  Map<String, int> getStatusDistribution() {
    final distribution = <String, int>{
      'active': 0,
      'inactive': 0,
      'blocked': 0,
      'vip': 0,
    };

    for (final customer in _customers) {
      distribution[customer.status] = (distribution[customer.status] ?? 0) + 1;
    }

    return distribution;
  }

  List<Customer> getNewCustomers({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _customers.where((c) => c.createdAt.isAfter(cutoffDate)).toList();
  }

  // Alias methods to match UI expectations
  Future<void> addCustomer(String merchantId, Customer customer) async {
    return await createCustomer(customer);
  }

  Future<void> addCustomerNote(String merchantId, CustomerNote note) async {
    return await createNote(note);
  }

  Future<void> addCustomerSegment(String merchantId, CustomerSegment segment) async {
    return await createSegment(segment);
  }

  Future<void> deleteCustomerSegment(String merchantId, String segmentId) async {
    try {
      await _customerService.deleteCustomerSegment(merchantId, segmentId);
      _customerSegments.removeWhere((s) => s.id == segmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting customer segment: $e');
      rethrow;
    }
  }



  // Get customer interactions for a specific customer
  List<CustomerInteraction> getCustomerInteractions(String customerId) {
    return _customerInteractions.where((interaction) => 
      interaction.customerId == customerId).toList()..sort((a, b) => 
      b.scheduledAt.compareTo(a.scheduledAt));
  }

  // Get customer notes for a specific customer  
  List<CustomerNote> getCustomerNotes(String customerId) {
    return _customerNotes.where((note) => 
      note.customerId == customerId).toList()..sort((a, b) => 
      b.createdAt.compareTo(a.createdAt));
  }

  // Add a customer interaction
  Future<void> addCustomerInteraction(String merchantId, CustomerInteraction interaction) async {
    try {
      // For now, just add to local list since CustomerService method doesn't exist yet
      _customerInteractions.add(interaction);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding customer interaction: $e');
      rethrow;
    }
  }
}