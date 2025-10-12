import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../../widgets/metartpay_branding.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({Key? key}) : super(key: key);

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _bvnController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedIdType;
  final List<String> _idTypes = [
    'National ID (NIN)',
    'Driver\'s License',
    'International Passport',
    'Voter\'s Card',
  ];

  @override
  void initState() {
    super.initState();
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final merchant = merchantProvider.currentMerchant;
    
    // Pre-fill with existing data if available
    _fullNameController.text = merchant?.fullName ?? '';
    _idNumberController.text = merchant?.idNumber ?? '';
    _bvnController.text = merchant?.bvn ?? '';
    _addressController.text = merchant?.address ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _bvnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitKYC() async {
    if (_formKey.currentState!.validate()) {
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: MetartPayColors.primary),
              SizedBox(height: 16),
              Text('Submitting KYC verification...'),
            ],
          ),
        ),
      );

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Update merchant with KYC info (in a real app, this would be an API call)
      final success = await merchantProvider.updateMerchantKYC(
        fullName: _fullNameController.text,
        idNumber: _idNumberController.text,
        bvn: _bvnController.text,
        address: _addressController.text,
        idType: _selectedIdType ?? '',
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text('KYC Submitted'),
              ],
            ),
            content: const Text(
              'Your KYC verification has been submitted successfully. '
              'We will review your information and update your status within 24-48 hours.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MetartPayColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to submit KYC verification. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MetartPayColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            color: MetartPayColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MetartPayColors.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: MetartPayColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Complete Your Identity Verification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verify your identity to unlock all features and start receiving payments securely.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form Fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter your full legal name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Please enter your full name (first and last name)';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ID Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIdType,
                      decoration: InputDecoration(
                        labelText: 'ID Type *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      items: _idTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIdType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an ID type';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ID Number
                    TextFormField(
                      controller: _idNumberController,
                      decoration: InputDecoration(
                        labelText: 'ID Number *',
                        hintText: 'Enter your ID number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.confirmation_number),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your ID number';
                        }
                        if (value.trim().length < 8) {
                          return 'ID number must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // BVN
                    TextFormField(
                      controller: _bvnController,
                      decoration: InputDecoration(
                        labelText: 'BVN (Bank Verification Number)',
                        hintText: 'Enter your 11-digit BVN',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 11) {
                            return 'BVN must be exactly 11 digits';
                          }
                          if (!RegExp(r'^\d+$').hasMatch(value)) {
                            return 'BVN must contain only numbers';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Residential Address *',
                        hintText: 'Enter your full address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a complete address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Process',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your information will be reviewed within 24-48 hours. You\'ll receive a notification once verification is complete.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitKYC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MetartPayColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit KYC Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Security Notice
              Text(
                'Your personal information is encrypted and secure. We comply with all data protection regulations.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}