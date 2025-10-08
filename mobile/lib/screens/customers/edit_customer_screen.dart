import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({
    super.key,
    required this.customer,
  });

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  
  late String _selectedTier;
  late String _selectedStatus;
  late bool _isVIP;
  late List<String> _tags;
  final TextEditingController _tagController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final customer = widget.customer;
    
    _firstNameController = TextEditingController(text: customer.firstName ?? '');
    _lastNameController = TextEditingController(text: customer.lastName ?? '');
    _emailController = TextEditingController(text: customer.email);
    _phoneController = TextEditingController(text: customer.phone ?? '');
    _addressController = TextEditingController(text: customer.address ?? '');
    _cityController = TextEditingController(text: customer.city ?? '');
    _stateController = TextEditingController(text: customer.state ?? '');
    _countryController = TextEditingController(text: customer.country ?? '');
    
    _selectedTier = customer.tier;
    _selectedStatus = customer.status;
    _isVIP = customer.isVIP;
    _tags = List<String>.from(customer.tags);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.customer.displayName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Stats Header
              _buildStatsCard(),
              
              const SizedBox(height: 20),

              // Basic Information
              _buildSection(
                'Basic Information',
                Icons.person,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+234...',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Address Information
              _buildSection(
                'Address Information',
                Icons.location_on,
                [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Customer Settings
              _buildSection(
                'Customer Settings',
                Icons.settings,
                [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTier,
                          decoration: const InputDecoration(
                            labelText: 'Customer Tier',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.workspace_premium),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'bronze', child: Text('Bronze')),
                            DropdownMenuItem(value: 'silver', child: Text('Silver')),
                            DropdownMenuItem(value: 'gold', child: Text('Gold')),
                            DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTier = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.circle),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                            DropdownMenuItem(value: 'vip', child: Text('VIP')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                                if (value == 'vip') {
                                  _isVIP = true;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('VIP Customer'),
                    subtitle: const Text('Mark as VIP for special treatment'),
                    value: _isVIP,
                    onChanged: (value) {
                      setState(() {
                        _isVIP = value;
                        if (value) {
                          _selectedStatus = 'vip';
                          if (_selectedTier == 'bronze') {
                            _selectedTier = 'gold';
                          }
                        } else if (_selectedStatus == 'vip') {
                          _selectedStatus = 'active';
                        }
                      });
                    },
                    activeColor: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tags Section
              _buildSection(
                'Tags',
                Icons.tag,
                [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., premium, frequent buyer',
                          ),
                          onFieldSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addTag(_tagController.text),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(color: Colors.blue[700]),
                      )).toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No tags added yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final customer = widget.customer;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getStatusColor(customer.status),
                  child: Text(
                    customer.displayName.isNotEmpty
                        ? customer.displayName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer since ${_formatDate(customer.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Total Spent',
                    '₦${customer.totalSpentNaira.toStringAsFixed(0)}',
                    Icons.money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Transactions',
                    customer.totalTransactions.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Loyalty Score',
                    '${customer.loyaltyScore}/100',
                    Icons.favorite,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

      if (merchantProvider.currentMerchant == null) {
        throw Exception('No merchant found');
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim();

      final updatedCustomer = widget.customer.copyWith(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        email: email,
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        city: _cityController.text.trim().isNotEmpty 
            ? _cityController.text.trim() 
            : null,
        state: _stateController.text.trim().isNotEmpty 
            ? _stateController.text.trim() 
            : null,
        country: _countryController.text.trim().isNotEmpty 
            ? _countryController.text.trim() 
            : null,
        tier: _selectedTier,
        status: _selectedStatus,
        isVIP: _isVIP,
        tags: _tags,
        updatedAt: DateTime.now(),
      );

      await customerProvider.updateCustomer(
        merchantProvider.currentMerchant!.id,
        updatedCustomer,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedCustomer.displayName} updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updatedCustomer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating customer: $e'),
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