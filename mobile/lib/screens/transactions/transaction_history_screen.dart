import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';
import '../../widgets/metartpay_branding.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load invoices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final merchantProvider = context.read<MerchantProvider>();
      merchantProvider.loadMerchantInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    var filtered = invoices;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((invoice) {
        return invoice.id.toLowerCase().contains(query) ||
               (invoice.metadata?['description']?.toLowerCase()?.contains(query) ?? false);
      }).toList();
    }

    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((invoice) => invoice.status == _statusFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Transaction History',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: 12),
                
                // Filter Chips
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _statusFilter == 'all',
                            selectedColor: MetartPayColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _statusFilter == 'all' ? Colors.white : MetartPayColors.primary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'all';
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Pending'),
                            selected: _statusFilter == 'pending',
                            selectedColor: MetartPayColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _statusFilter == 'pending' ? Colors.white : MetartPayColors.primary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'pending';
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Paid'),
                            selected: _statusFilter == 'paid',
                            selectedColor: MetartPayColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _statusFilter == 'paid' ? Colors.white : MetartPayColors.primary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'paid';
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Cancelled'),
                            selected: _statusFilter == 'cancelled',
                            selectedColor: MetartPayColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _statusFilter == 'cancelled' ? Colors.white : MetartPayColors.primary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'cancelled';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: Consumer<MerchantProvider>(
              builder: (context, merchantProvider, child) {
                if (merchantProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (merchantProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading transactions',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          merchantProvider.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            merchantProvider.loadMerchantInvoices();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allInvoices = merchantProvider.invoices;
                final filteredInvoices = _filterInvoices(allInvoices);

                if (filteredInvoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allInvoices.isEmpty
                              ? 'You haven\'t created any payment links yet.'
                              : 'Try adjusting your search or filter criteria.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // All transactions
                    _buildTransactionList(filteredInvoices),
                    // Pending transactions
                    _buildTransactionList(
                      filteredInvoices.where((i) => i.status == 'pending').toList(),
                    ),
                    // Completed transactions
                    _buildTransactionList(
                      filteredInvoices.where((i) => i.status == 'paid').toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return const Center(
        child: Text('No transactions in this category'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final merchantProvider = context.read<MerchantProvider>();
        await merchantProvider.loadMerchantInvoices();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return _TransactionCard(
            invoice: invoice,
            onTap: () => _showTransactionDetails(context, invoice),
          );
        },
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransactionDetailsSheet(invoice: invoice),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = invoice.metadata?['description'] ?? 'Payment Link';
    final createdAt = invoice.createdAt;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invoice.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(invoice.status),
            color: _getStatusColor(invoice.status),
          ),
        ),
        title: Text(
          description,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '₦${NumberFormat('#,##0.00').format(invoice.amountNaira)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(invoice.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Invoice invoice;

  const _TransactionDetailsSheet({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = invoice.metadata?['description'] ?? 'Payment Link';
    final createdAt = invoice.createdAt;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transaction Details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Details
          _DetailRow(
            label: 'Transaction ID',
            value: invoice.id,
            copyable: true,
          ),
          _DetailRow(
            label: 'Description',
            value: description,
          ),
          _DetailRow(
            label: 'Amount',
            value: '₦${NumberFormat('#,##0.00').format(invoice.amountNaira)}',
          ),
          _DetailRow(
            label: 'Status',
            value: invoice.status.toUpperCase(),
            valueColor: _getStatusColor(invoice.status),
          ),
          _DetailRow(
            label: 'Chain',
            value: invoice.chain.toUpperCase(),
          ),
          _DetailRow(
            label: 'Token',
            value: invoice.cryptoSymbol,
          ),
          _DetailRow(
            label: 'Created',
            value: DateFormat('MMM dd, yyyy at HH:mm').format(createdAt),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Copy transaction ID to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction ID copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Transaction ID'),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool copyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    onPressed: () {
                      // TODO: Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}