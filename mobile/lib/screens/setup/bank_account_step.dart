import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/metartpay_branding.dart';
import '../../services/bank_verification_service.dart';

class BankAccountStep extends StatefulWidget {
  final Map<String, dynamic> setupData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const BankAccountStep({
    Key? key,
    required this.setupData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<BankAccountStep> createState() => _BankAccountStepState();
}

class _BankAccountStepState extends State<BankAccountStep> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  List<Map<String, dynamic>> _nigeriaBanks = [];
  Map<String, dynamic>? _selectedBank;
  bool _isVerifying = false;
  bool _isLoadingBanks = true;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    
    // Initialize controllers with existing data
    _accountNumberController.text = widget.setupData['bankAccountNumber'] ?? '';
    _accountNameController.text = widget.setupData['bankAccountName'] ?? '';
    
    // Initialize selected bank if available
    final savedBankName = widget.setupData['bankName'];
    if (savedBankName != null && savedBankName.isNotEmpty) {
      // Will be set after banks are loaded
    }
    
    // Listen for account number changes to trigger verification
    _accountNumberController.addListener(_onAccountNumberChanged);
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await BankVerificationService.getNigerianBanks();
      setState(() {
        _nigeriaBanks = banks;
        _isLoadingBanks = false;
        
        // Set selected bank if we have saved data
        final savedBankName = widget.setupData['bankName'];
        if (savedBankName != null && savedBankName.isNotEmpty) {
          _selectedBank = banks.firstWhere(
            (bank) => bank['name'] == savedBankName,
            orElse: () => {},
          );
          if (_selectedBank!.isEmpty) _selectedBank = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingBanks = false;
      });
    }
  }

  void _onAccountNumberChanged() {
    if (_accountNumberController.text.length == 10 && _selectedBank != null) {
      _verifyAccount();
    } else {
      setState(() {
        _accountNameController.text = '';
        _verificationError = null;
      });
    }
  }

  @override
  void dispose() {
    _accountNumberController.removeListener(_onAccountNumberChanged);
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccount() async {
    if (_accountNumberController.text.length != 10 || _selectedBank == null) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      final result = await BankVerificationService.verifyBankAccount(
        accountNumber: _accountNumberController.text,
        bankCode: _selectedBank!['code'],
      );

      setState(() {
        _isVerifying = false;
        
        if (result.success && result.accountName != null) {
          _accountNameController.text = result.accountName!;
          _verificationError = null;
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Account verified: ${result.accountName}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          _accountNameController.text = '';
          _verificationError = result.error ?? 'Account verification failed';
        }
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationError = 'Network error. Please try again.';
        _accountNameController.text = '';
      });
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Check if account is verified
      if (_accountNameController.text.isEmpty && _verificationError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for account verification to complete'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (_verificationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please resolve account verification error: $_verificationError'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Update setup data
      widget.onDataUpdate('bankAccountNumber', _accountNumberController.text);
      widget.onDataUpdate('bankName', _selectedBank!['name']);
      widget.onDataUpdate('bankAccountName', _accountNameController.text);
      
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Bank Account Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: MetartPayColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your bank account to receive payments in Naira.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Bank Selection
                    _isLoadingBanks
                        ? Container(
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading banks...'),
                                ],
                              ),
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: _selectedBank,
                            decoration: InputDecoration(
                              labelText: 'Bank *',
                              hintText: 'Select your bank',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.account_balance),
                            ),
                            items: _nigeriaBanks.map((bank) {
                              return DropdownMenuItem(
                                value: bank,
                                child: Text(bank['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBank = value;
                                // Clear account name and error when bank changes
                                _accountNameController.clear();
                                _verificationError = null;
                              });
                              if (_accountNumberController.text.length == 10) {
                                _verifyAccount();
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a bank';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 20),

                    // Account Number
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Account Number *',
                        hintText: 'Enter 10-digit account number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.numbers),
                        suffixIcon: _isVerifying
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _accountNumberController.text.length == 10 && _selectedBank != null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                      ),
                      onChanged: (value) {
                        if (value.length == 10 && _selectedBank != null) {
                          _verifyAccount();
                        } else {
                          setState(() {
                            _accountNameController.clear();
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Account number is required';
                        }
                        if (value.length != 10) {
                          return 'Account number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Account Name (Auto-filled after verification)
                    TextFormField(
                      controller: _accountNameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Account Name',
                        hintText: 'Will be filled after verification',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please verify your account number first';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    
                    // Security Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.green.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure & Encrypted',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your bank details are encrypted and stored securely. We never store your banking passwords.',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: MetartPayColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: MetartPayColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MetartPayButton(
                    text: 'Continue',
                    onPressed: _handleNext,
                    isGradient: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}