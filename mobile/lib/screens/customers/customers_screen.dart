import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';
import 'customer_segments_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCustomers() {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    if (merchantProvider.currentMerchant != null) {
      customerProvider.refreshAllData(merchantProvider.currentMerchant!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.segment),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerSegmentsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'VIP'),
            Tab(text: 'Returning'),
            Tab(text: 'Need Attention'),
          ],
        ),
      ),
      body: Consumer2<CustomerProvider, MerchantProvider>(
        builder: (context, customerProvider, merchantProvider, child) {
          if (merchantProvider.currentMerchant == null) {
            return const Center(
              child: Text('Please complete merchant setup to view customers'),
            );
          }

          return Column(
            children: [
              // Search and Statistics Overview
              _buildSearchAndStats(customerProvider),
              
              // Customer Lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCustomersList(customerProvider.filteredCustomers),
                    _buildCustomersList(customerProvider.activeCustomers),
                    _buildCustomersList(customerProvider.vipCustomers),
                    _buildCustomersList(customerProvider.returningCustomers),
                    _buildCustomersList(customerProvider.customersNeedingAttention),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCustomerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndStats(CustomerProvider customerProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      customerProvider.setSearchQuery('');
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              customerProvider.setSearchQuery(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Quick Stats
          if (!customerProvider.isLoadingCustomers) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    customerProvider.totalCustomers.toString(),
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    customerProvider.activeCustomersCount.toString(),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'VIP',
                    customerProvider.vipCustomersCount.toString(),
                    Colors.purple,
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Need Attention',
                    customerProvider.customersNeedingAttentionCount.toString(),
                    Colors.orange,
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList(List<Customer> customers) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        if (customerProvider.isLoadingCustomers) {
          return const Center(child: CircularProgressIndicator());
        }

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No customers found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or add a new customer',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCustomers(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return _buildCustomerCard(customer);
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            Row(
              children: [
                // Customer Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStatusColor(customer.status),
                  child: Text(
                    customer.displayName.isNotEmpty 
                      ? customer.displayName[0].toUpperCase()
                      : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Customer Tags
                          if (customer.isVIP)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        customer.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      if (customer.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.phone!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '₦${customer.totalSpentNaira.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.receipt, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${customer.totalTransactions} transactions',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Status and Tier Indicators
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTierColor(customer.tier).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getTierColor(customer.tier)),
                      ),
                      child: Text(
                        customer.tier.toUpperCase(),
                        style: TextStyle(
                          color: _getTierColor(customer.tier),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(customer.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      customer.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (customer.requiresAttention) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Needs attention - ${customer.daysSinceLastTransaction} days since last transaction',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'blocked':
        return Colors.red;
      case 'vip':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'platinum':
        return Colors.grey[700]!;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Consumer<CustomerProvider>(
          builder: (context, customerProvider, child) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Customers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            customerProvider.clearFilters();
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Filter Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Status Filter
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['active', 'inactive', 'blocked', 'vip']
                              .map((status) => FilterChip(
                                    label: Text(status),
                                    selected: customerProvider.selectedStatus == status,
                                    onSelected: (selected) {
                                      customerProvider.setStatusFilter(
                                        selected ? status : null,
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tier Filter
                        const Text(
                          'Tier',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['bronze', 'silver', 'gold', 'platinum']
                              .map((tier) => FilterChip(
                                    label: Text(tier),
                                    selected: customerProvider.selectedTier == tier,
                                    onSelected: (selected) {
                                      customerProvider.setTierFilter(
                                        selected ? tier : null,
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sort Options
                        const Text(
                          'Sort By',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: customerProvider.sortBy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'updatedAt', child: Text('Last Updated')),
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                            DropdownMenuItem(value: 'totalSpent', child: Text('Total Spent')),
                            DropdownMenuItem(value: 'totalTransactions', child: Text('Transactions')),
                            DropdownMenuItem(value: 'lastTransaction', child: Text('Last Transaction')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              customerProvider.setSorting(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Apply Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}