import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/metartpay_branding.dart';

class KYCDetailsStep extends StatefulWidget {
  final Map<String, dynamic> setupData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const KYCDetailsStep({
    Key? key,
    required this.setupData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<KYCDetailsStep> createState() => _KYCDetailsStepState();
}

class _KYCDetailsStepState extends State<KYCDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _bvnController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _fullNameController.text = widget.setupData['fullName'] ?? '';
    _idNumberController.text = widget.setupData['idNumber'] ?? '';
    _bvnController.text = widget.setupData['bvn'] ?? '';
    _addressController.text = widget.setupData['address'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _bvnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Update setup data
      widget.onDataUpdate('fullName', _fullNameController.text);
      widget.onDataUpdate('idNumber', _idNumberController.text);
      widget.onDataUpdate('bvn', _bvnController.text);
      widget.onDataUpdate('address', _addressController.text);
      
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
              'Personal Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: MetartPayColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We need to verify your identity to comply with financial regulations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ID Number (Optional)
                    TextFormField(
                      controller: _idNumberController,
                      decoration: InputDecoration(
                        labelText: 'National ID Number (Optional)',
                        hintText: 'Enter your national ID number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BVN (Optional)
                    TextFormField(
                      controller: _bvnController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: InputDecoration(
                        labelText: 'BVN (Optional)',
                        hintText: 'Enter your Bank Verification Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.account_balance),
                        helperText: 'This helps with bank account verification',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length != 11) {
                          return 'BVN must be 11 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Address (Optional)
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Residential Address (Optional)',
                        hintText: 'Enter your residential address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.home),
                        alignLabelWithHint: true,
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
                          Icon(Icons.info, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Optional fields help us verify your account faster and may unlock additional features.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 14,
                              ),
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