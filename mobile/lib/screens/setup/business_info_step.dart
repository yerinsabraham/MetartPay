import 'package:flutter/material.dart';
import '../../widgets/metartpay_branding.dart';

class BusinessInfoStep extends StatefulWidget {
  final Map<String, dynamic> setupData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;

  const BusinessInfoStep({
    Key? key,
    required this.setupData,
    required this.onDataUpdate,
    required this.onNext,
  }) : super(key: key);

  @override
  State<BusinessInfoStep> createState() => _BusinessInfoStepState();
}

class _BusinessInfoStepState extends State<BusinessInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _businessAddressController = TextEditingController();

  final List<String> _industries = [
    'E-commerce',
    'Fashion & Retail',
    'Food & Restaurants',
    'Technology',
    'Healthcare',
    'Education',
    'Real Estate',
    'Financial Services',
    'Entertainment',
    'Professional Services',
    'Other',
  ];

  String? _selectedIndustry;
  String? _selectedTier;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _businessNameController.text = widget.setupData['businessName'] ?? '';
    _industryController.text = widget.setupData['industry'] ?? '';
    _contactEmailController.text = widget.setupData['contactEmail'] ?? '';
    _businessAddressController.text = widget.setupData['businessAddress'] ?? '';
  _selectedTier = widget.setupData['merchantTier']?.isEmpty == true ? null : widget.setupData['merchantTier'];
    _selectedIndustry = widget.setupData['industry']?.isEmpty == true 
        ? null 
        : widget.setupData['industry'];
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _industryController.dispose();
    _contactEmailController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Update setup data
      widget.onDataUpdate('businessName', _businessNameController.text);
      widget.onDataUpdate('industry', _selectedIndustry ?? '');
      widget.onDataUpdate('merchantTier', _selectedTier ?? 'Tier0_Unregistered');
      widget.onDataUpdate('contactEmail', _contactEmailController.text);
      widget.onDataUpdate('businessAddress', _businessAddressController.text);
      
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
              'Tell us about your business',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: MetartPayColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This information helps us customize MetartPay for your business needs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Business Name
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name *',
                        hintText: 'Enter your business name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                            ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Industry Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIndustry,
                      decoration: InputDecoration(
                        labelText: 'Industry *',
                        hintText: 'Select your industry',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: _industries.map((industry) {
                        return DropdownMenuItem(
                          value: industry,
                          child: Text(industry),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIndustry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an industry';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Contact Email
                    TextFormField(
                      controller: _contactEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Business Email *',
                        hintText: 'contact@yourbusiness.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                            ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Business Address (Optional)
                    TextFormField(
                      controller: _businessAddressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Business Address (Optional)',
                        hintText: 'Enter your business address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Merchant Type / Tier
                    DropdownButtonFormField<String>(
                      value: _selectedTier,
                      decoration: InputDecoration(
                        labelText: 'Business Type',
                        hintText: 'Select your business type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tier0_Unregistered', child: Text('Sole Proprietor / Unregistered')),
                        DropdownMenuItem(value: 'Tier1_BusinessName', child: Text('Registered Business Name')),
                        DropdownMenuItem(value: 'Tier2_LimitedCompany', child: Text('Limited Company (Registered)')),
                      ],
                      onChanged: (v) => setState(() { _selectedTier = v; }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: MetartPayButton(
                text: 'Continue',
                onPressed: _handleNext,
                isGradient: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}