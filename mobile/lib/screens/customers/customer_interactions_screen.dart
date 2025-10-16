import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state_widget.dart';

class CustomerInteractionsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerInteractionsScreen({super.key, required this.customer});

  @override
  State<CustomerInteractionsScreen> createState() => _CustomerInteractionsScreenState();
}

class _CustomerInteractionsScreenState extends State<CustomerInteractionsScreen> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name} - Interactions'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddInteractionDialog,
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final interactions = customerProvider.getCustomerInteractions(widget.customer.id);
          
          if (interactions.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                title: 'No Interactions',
                subtitle: 'No interactions recorded for this customer yet.',
                icon: Icons.chat_bubble_outline,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interactions.length,
            itemBuilder: (context, index) {
              final interaction = interactions[index];
              return _buildInteractionCard(interaction, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildInteractionCard(CustomerInteraction interaction, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getInteractionIcon(interaction.type),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    interaction.type.toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  _formatDate(interaction.scheduledAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (interaction.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                interaction.content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'By ${interaction.createdBy}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInteractionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'meeting':
        return Icons.people;
      case 'support':
        return Icons.support_agent;
      case 'complaint':
        return Icons.warning;
      case 'compliment':
        return Icons.thumb_up;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddInteractionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interaction'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Interaction Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'call', child: Text('Phone Call')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                  DropdownMenuItem(value: 'support', child: Text('Support')),
                  DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                  DropdownMenuItem(value: 'compliment', child: Text('Compliment')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an interaction type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter interaction notes';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedType = null);
              _notesController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _addInteraction,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addInteraction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

      final interaction = CustomerInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: widget.customer.id,
        merchantId: widget.customer.merchantId,
        type: _selectedType ?? 'other',
        subject: 'Customer Interaction',
        content: _notesController.text.trim(),
        scheduledAt: DateTime.now(),
        createdBy: authProvider.currentUser!.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await customerProvider.addCustomerInteraction(
        widget.customer.merchantId,
        interaction,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding interaction: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}