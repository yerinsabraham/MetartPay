import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';

class CustomerSegmentsScreen extends StatefulWidget {
  const CustomerSegmentsScreen({super.key});

  @override
  State<CustomerSegmentsScreen> createState() => _CustomerSegmentsScreenState();
}

class _CustomerSegmentsScreenState extends State<CustomerSegmentsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  void _loadSegments() {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    
    if (merchantProvider.currentMerchant != null) {
      customerProvider.loadCustomerSegments(merchantProvider.currentMerchant!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Segments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSegments,
          ),
        ],
      ),
      body: Consumer2<CustomerProvider, MerchantProvider>(
        builder: (context, customerProvider, merchantProvider, child) {
          if (merchantProvider.currentMerchant == null) {
            return const Center(
              child: Text('Please complete merchant setup to view segments'),
            );
          }

          if (customerProvider.isLoadingSegments) {
            return const Center(child: CircularProgressIndicator());
          }

          final segments = customerProvider.customerSegments;

          if (segments.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Segment Statistics
              _buildSegmentStats(customerProvider),
              
              // Segments List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    final segment = segments[index];
                    return _buildSegmentCard(segment, customerProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSegmentDialog,
        label: const Text('New Segment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.segment,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Customer Segments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create segments to group your customers\nbased on behavior and characteristics',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateSegmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Segment'),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentStats(CustomerProvider customerProvider) {
    final totalSegments = customerProvider.customerSegments.length;
    final activeSegments = customerProvider.customerSegments
        .where((s) => s.isActive)
        .length;
    final dynamicSegments = customerProvider.customerSegments
        .where((s) => s.type == 'dynamic')
        .length;

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
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalSegments.toString(),
              Colors.blue,
              Icons.segment,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeSegments.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Dynamic',
              dynamicSegments.toString(),
              Colors.purple,
              Icons.auto_awesome,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(CustomerSegment segment, CustomerProvider customerProvider) {
    final customerCount = customerProvider.customers
        .where((customer) => _customerMatchesSegment(customer, segment))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSegmentDetails(segment, customerProvider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: segment.isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          segment.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (segment.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            segment.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSegmentTypeColor(segment.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSegmentTypeColor(segment.type),
                          ),
                        ),
                        child: Text(
                          segment.type.toUpperCase(),
                          style: TextStyle(
                            color: _getSegmentTypeColor(segment.type),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$customerCount customers',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Segment Criteria (for dynamic segments)
              if (segment.type == 'dynamic' && segment.criteria.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dynamic Criteria:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...segment.criteria.entries.take(3).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• ${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      if (segment.criteria.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• +${segment.criteria.length - 3} more criteria',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewSegmentCustomers(segment, customerProvider),
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('View Customers'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _editSegment(segment),
                    icon: const Icon(Icons.edit, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteSegment(segment),
                    icon: const Icon(Icons.delete, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSegmentTypeColor(String type) {
    switch (type) {
      case 'dynamic':
        return Colors.purple;
      case 'static':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _customerMatchesSegment(Customer customer, CustomerSegment segment) {
    if (segment.type == 'static') {
      return segment.customerIds.contains(customer.id);
    }
    
    // For dynamic segments, check criteria
    for (final entry in segment.criteria.entries) {
      switch (entry.key) {
        case 'tier':
          if (customer.tier != entry.value) return false;
          break;
        case 'status':
          if (customer.status != entry.value) return false;
          break;
        case 'isVIP':
          if (customer.isVIP.toString() != entry.value) return false;
          break;
        case 'minTotalSpent':
          if (customer.totalSpentNaira < double.parse(entry.value)) return false;
          break;
        case 'minTransactions':
          if (customer.totalTransactions < int.parse(entry.value)) return false;
          break;
      }
    }
    
    return true;
  }

  void _showCreateSegmentDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateSegmentDialog(),
    ).then((result) {
      if (result == true) {
        _loadSegments();
      }
    });
  }

  void _showSegmentDetails(CustomerSegment segment, CustomerProvider customerProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SegmentDetailsSheet(
          segment: segment,
          customerProvider: customerProvider,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _viewSegmentCustomers(CustomerSegment segment, CustomerProvider customerProvider) {
    final customers = customerProvider.customers
        .where((customer) => _customerMatchesSegment(customer, segment))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${segment.name} (${customers.length} customers)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text('No customers in this segment'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  customer.displayName.isNotEmpty
                                      ? customer.displayName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(customer.displayName),
                              subtitle: Text(customer.email),
                              trailing: Text(
                                '₦${customer.totalSpentNaira.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editSegment(CustomerSegment segment) {
    // TODO: Implement segment editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit segment feature coming soon')),
    );
  }

  void _deleteSegment(CustomerSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Segment'),
        content: Text(
          'Are you sure you want to delete the segment "${segment.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
              final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
              
              try {
                await customerProvider.deleteCustomerSegment(
                  merchantProvider.currentMerchant!.id,
                  segment.id,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Segment "${segment.name}" deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting segment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CreateSegmentDialog extends StatefulWidget {
  const CreateSegmentDialog({super.key});

  @override
  State<CreateSegmentDialog> createState() => _CreateSegmentDialogState();
}

class _CreateSegmentDialogState extends State<CreateSegmentDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'dynamic';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Customer Segment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Segment Name',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Segment Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'dynamic',
                  child: Text('Dynamic (Auto-updates based on criteria)'),
                ),
                DropdownMenuItem(
                  value: 'static',
                  child: Text('Static (Manual customer selection)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSegment,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createSegment() async {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

      final segment = CustomerSegment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchantId: merchantProvider.currentMerchant!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: _selectedType,
        criteria: {},
        customerIds: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await customerProvider.addCustomerSegment(
        merchantProvider.currentMerchant!.id,
        segment,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Segment "${segment.name}" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating segment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class SegmentDetailsSheet extends StatelessWidget {
  final CustomerSegment segment;
  final CustomerProvider customerProvider;
  final ScrollController scrollController;

  const SegmentDetailsSheet({
    super.key,
    required this.segment,
    required this.customerProvider,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.segment, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        segment.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: segment.isActive ? Colors.green[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: segment.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        segment.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: segment.isActive ? Colors.green[700] : Colors.grey[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (segment.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    segment.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Segment Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Segment Information',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Type', segment.type.toUpperCase()),
                        _buildInfoRow('Created', _formatDate(segment.createdAt)),
                        _buildInfoRow('Last Updated', _formatDate(segment.updatedAt)),
                      ],
                    ),
                  ),
                ),
                
                if (segment.type == 'dynamic' && segment.criteria.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dynamic Criteria',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...segment.criteria.entries.map(
                            (entry) => _buildInfoRow(
                              entry.key.replaceAllMapped(
                                RegExp(r'([A-Z])'),
                                (match) => ' ${match.group(0)!.toLowerCase()}',
                              ).trim(),
                              entry.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}