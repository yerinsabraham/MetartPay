import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Customer? _currentCustomer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentCustomer = widget.customer;
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCustomerData() {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    
    if (merchantProvider.currentMerchant != null) {
      customerProvider.loadCustomerInteractions(widget.customer.id);
      customerProvider.loadCustomerNotes(widget.customer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer?.displayName ?? 'Customer Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditCustomerScreen(customer: _currentCustomer!),
                ),
              ).then((updatedCustomer) {
                if (updatedCustomer != null && updatedCustomer is Customer) {
                  setState(() {
                    _currentCustomer = updatedCustomer;
                  });
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block Customer'),
                  ],
                ),
              ),
              if (_currentCustomer?.isVIP != true)
                const PopupMenuItem(
                  value: 'make_vip',
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Make VIP'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Transactions'),
            Tab(text: 'Interactions'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: Consumer2<CustomerProvider, MerchantProvider>(
        builder: (context, customerProvider, merchantProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildTransactionsTab(),
              _buildInteractionsTab(),
              _buildNotesTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActionDialog,
        label: const Text('Quick Action'),
        icon: const Icon(Icons.flash_on),
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_currentCustomer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final customer = _currentCustomer!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Header Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _getStatusColor(customer.status),
                        child: Text(
                          customer.displayName.isNotEmpty
                              ? customer.displayName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    customer.displayName,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (customer.isVIP)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, 
                                      vertical: 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'VIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTierColor(customer.tier).withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getTierColor(customer.tier),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium,
                                        size: 16,
                                        color: _getTierColor(customer.tier),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer.tier.toUpperCase(),
                                        style: TextStyle(
                                          color: _getTierColor(customer.tier),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(customer.status).withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(customer.status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        customer.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(customer.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (customer.requiresAttention) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attention Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                Text(
                                  '${customer.daysSinceLastTransaction} days since last transaction',
                                  style: TextStyle(
                                    color: Colors.orange[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Information
          _buildInfoSection(
            'Contact Information',
            Icons.contact_mail,
            [
              _buildInfoRow('Email', customer.email, Icons.email),
              if (customer.phone != null)
                _buildInfoRow('Phone', customer.phone!, Icons.phone),
              if (customer.address != null)
                _buildInfoRow('Address', customer.address!, Icons.location_on),
              if (customer.city != null)
                _buildInfoRow('City', customer.city!, Icons.location_city),
              if (customer.country != null)
                _buildInfoRow('Country', customer.country!, Icons.flag),
            ],
          ),

          const SizedBox(height: 16),

          // Transaction Statistics
          _buildInfoSection(
            'Transaction Statistics',
            Icons.analytics,
            [
              _buildInfoRow(
                'Total Spent',
                '₦${customer.totalSpentNaira.toStringAsFixed(0)}',
                Icons.money,
              ),
              _buildInfoRow(
                'Total Transactions',
                customer.totalTransactions.toString(),
                Icons.receipt,
              ),
              _buildInfoRow(
                'Average Transaction',
                '₦${customer.averageTransactionValue.toStringAsFixed(0)}',
                Icons.trending_up,
              ),
              if (customer.lastTransactionDate != null)
                _buildInfoRow(
                  'Last Transaction',
                  _formatDate(customer.lastTransactionDate!),
                  Icons.schedule,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Engagement Metrics
          _buildInfoSection(
            'Engagement Metrics',
            Icons.insights,
            [
              _buildInfoRow(
                'Loyalty Score',
                '${customer.loyaltyScore}/100',
                Icons.favorite,
              ),
              _buildInfoRow(
                'Risk Score',
                '${customer.riskScore}/100',
                Icons.security,
              ),
              _buildInfoRow(
                'Last Login',
                customer.lastLoginDate != null
                    ? _formatDate(customer.lastLoginDate!)
                    : 'Never',
                Icons.login,
              ),
              _buildInfoRow(
                'Account Created',
                _formatDate(customer.createdAt),
                Icons.person_add,
              ),
            ],
          ),

          if (customer.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTagsSection(customer.tags),
          ],

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.blue[50],
                labelStyle: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Transaction History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon - Integration with payment history',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionsTab() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        final interactions = customerProvider.customerInteractions
            .where((interaction) => interaction.customerId == _currentCustomer!.id)
            .toList();

        if (customerProvider.isLoadingInteractions) {
          return const Center(child: CircularProgressIndicator());
        }

        if (interactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No interactions yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a conversation or log an interaction',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addInteraction(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Interaction'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: interactions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.add_comment, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add New Interaction',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _addInteraction(),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final interaction = interactions[index - 1];
            return _buildInteractionCard(interaction);
          },
        );
      },
    );
  }

  Widget _buildInteractionCard(CustomerInteraction interaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getInteractionTypeColor(interaction.type).withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interaction.type.toUpperCase(),
                    style: TextStyle(
                      color: _getInteractionTypeColor(interaction.type),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(interaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              interaction.subject ?? 'No Subject',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            if (interaction.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                interaction.notes!,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        final notes = customerProvider.customerNotes
            .where((note) => note.customerId == _currentCustomer!.id)
            .toList();

        if (customerProvider.isLoadingNotes) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No notes yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add notes to keep track of important information',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addNote(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.note_add, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add New Note',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _addNote(),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final note = notes[index - 1];
            return _buildNoteCard(note);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(CustomerNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getNotePriorityColor(note.priority ?? 'low').withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (note.priority ?? 'low').toUpperCase(),
                    style: TextStyle(
                      color: _getNotePriorityColor(note.priority ?? 'low'),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(note.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              note.content,
              style: const TextStyle(fontSize: 14),
            ),
            
            if (note.reminderDate != null &&
                note.reminderDate!.isAfter(DateTime.now())) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder: ${_formatDate(note.reminderDate!)}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
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

  Color _getInteractionTypeColor(String type) {
    switch (type) {
      case 'email':
        return Colors.blue;
      case 'call':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'support':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getNotePriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action) async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

    if (merchantProvider.currentMerchant == null) return;

    switch (action) {
      case 'block':
        _showBlockCustomerDialog();
        break;
      case 'make_vip':
          // capture id and newCustomer locally before awaiting
          final merchantId = merchantProvider.currentMerchant!.id;
          final updated = _currentCustomer!.copyWith(isVIP: true, tier: 'gold');
          await customerProvider.updateCustomer(merchantId, updated);
          if (!mounted) return;
          setState(() {
            _currentCustomer = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer promoted to VIP')),
          );
        break;
      case 'export':
        // TODO: Implement export functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export feature coming soon')),
        );
        break;
    }
  }

  void _showBlockCustomerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block Customer'),
        content: Text(
          'Are you sure you want to block ${_currentCustomer!.displayName}? '
          'This will prevent them from making transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // close the dialog first using the dialog's context
              Navigator.of(dialogContext).pop();

              // use the State's context / providers (capture before awaiting)
              final customerProvider = Provider.of<CustomerProvider>(this.context, listen: false);
              final merchantProvider = Provider.of<MerchantProvider>(this.context, listen: false);

              final merchantId = merchantProvider.currentMerchant!.id;
              final updated = _currentCustomer!.copyWith(status: 'blocked');

              await customerProvider.updateCustomer(merchantId, updated);

              if (!mounted) return;
              setState(() {
                _currentCustomer = updated;
              });
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Customer blocked')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_comment, color: Colors.blue),
              title: const Text('Add Interaction'),
              onTap: () {
                Navigator.of(context).pop();
                _addInteraction();
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.green),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.of(context).pop();
                _addNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement email functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.call, color: Colors.purple),
              title: const Text('Call Customer'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addInteraction() {
    // TODO: Navigate to add interaction screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add interaction screen coming soon')),
    );
  }

  void _addNote() {
    // TODO: Navigate to add note screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add note screen coming soon')),
    );
  }
}