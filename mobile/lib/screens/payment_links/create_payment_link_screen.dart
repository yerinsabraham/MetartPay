import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_link_provider.dart';
import '../../providers/merchant_provider.dart';

class CreatePaymentLinkScreen extends StatefulWidget {
  const CreatePaymentLinkScreen({super.key});

  @override
  State<CreatePaymentLinkScreen> createState() => _CreatePaymentLinkScreenState();
}

class _CreatePaymentLinkScreenState extends State<CreatePaymentLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _availableNetworks = ['ETH', 'BSC', 'MATIC'];
  final List<String> _availableTokens = ['USDT', 'USDC'];
  
  Set<String> _selectedNetworks = {'ETH', 'BSC'};
  Set<String> _selectedTokens = {'USDT', 'USDC'};
  
  DateTime? _expiryDate;
  bool _hasExpiry = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Payment Link'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<PaymentLinkProvider>(
        builder: (context, paymentLinkProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard(
                  title: 'Payment Information',
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Payment Title *',
                        hintText: 'e.g., "Product Purchase", "Service Payment"',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a payment title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Additional details about this payment',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (NGN) *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.money),
                        prefixText: '₦ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Accepted Networks',
                  children: [
                    const Text(
                      'Select which blockchain networks customers can use to pay:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableNetworks.map((network) {
                        final isSelected = _selectedNetworks.contains(network);
                        return FilterChip(
                          label: Text(_getNetworkDisplayName(network)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedNetworks.add(network);
                              } else {
                                // Ensure at least one network is selected
                                if (_selectedNetworks.length > 1) {
                                  _selectedNetworks.remove(network);
                                }
                              }
                            });
                          },
                          avatar: isSelected 
                              ? const Icon(Icons.check_circle, size: 18)
                              : const Icon(Icons.circle_outlined, size: 18),
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Accepted Tokens',
                  children: [
                    const Text(
                      'Select which stablecoins customers can use:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTokens.map((token) {
                        final isSelected = _selectedTokens.contains(token);
                        return FilterChip(
                          label: Text(token),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTokens.add(token);
                              } else {
                                // Ensure at least one token is selected
                                if (_selectedTokens.length > 1) {
                                  _selectedTokens.remove(token);
                                }
                              }
                            });
                          },
                          avatar: isSelected 
                              ? const Icon(Icons.check_circle, size: 18)
                              : const Icon(Icons.circle_outlined, size: 18),
                          selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).colorScheme.secondary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Expiration (Optional)',
                  children: [
                    SwitchListTile(
                      title: const Text('Set expiration date'),
                      subtitle: const Text('Payment link will expire automatically'),
                      value: _hasExpiry,
                      onChanged: (value) {
                        setState(() {
                          _hasExpiry = value;
                          if (!value) {
                            _expiryDate = null;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_hasExpiry) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _expiryDate == null
                                      ? 'Select expiration date'
                                      : 'Expires: ${_formatDate(_expiryDate!)}',
                                  style: TextStyle(
                                    color: _expiryDate == null ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _buildPreview(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createPaymentLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create Payment Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _titleController.text.isEmpty ? 'Payment Title' : _titleController.text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _titleController.text.isEmpty ? Colors.grey : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_descriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _descriptionController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '₦${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _selectedNetworks.expand((network) {
                      return _selectedTokens.map((token) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            '$network $token',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                  if (_hasExpiry && _expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expires ${_formatDate(_expiryDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNetworkDisplayName(String network) {
    switch (network) {
      case 'ETH':
        return 'Ethereum';
      case 'BSC':
        return 'Binance Smart Chain';
      case 'MATIC':
        return 'Polygon';
      default:
        return network;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() {
        _expiryDate = selected;
      });
    }
  }

  Future<void> _createPaymentLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedNetworks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one network'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasExpiry && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiration date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
      
      final result = await paymentLinkProvider.createPaymentLink(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        networks: _selectedNetworks.toList(),
        tokens: _selectedTokens.toList(),
        expiresAt: _expiryDate,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment link created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create payment link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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