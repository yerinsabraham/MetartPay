import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      // KYC files are stored in-memory as a list of PlatformFile
      // They should not be persisted directly to Firestore via partial save
      // but will be passed to the final create call.
      widget.onDataUpdate('kycFiles', _pickedFiles);
      
      widget.onNext();
    }
  }

  List<PlatformFile> _pickedFiles = [];

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: false, // prefer path for upload
      );

      if (result != null && result.files.isNotEmpty) {
        // Enforce size limit client-side as well
        const int maxBytes = 5 * 1024 * 1024;
        final validFiles = result.files.where((f) => f.size <= maxBytes).toList();
        final oversized = result.files.where((f) => f.size > maxBytes).toList();

        if (oversized.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('One or more selected files exceed 5MB and were ignored.')),
          );
        }

        setState(() {
          _pickedFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      AppLogger.e('Error picking document: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: $e')),
      );
    }
  }

  void _removePickedFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.home),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Document upload area
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload ID / KYC Documents', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickDocument,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Select files'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_pickedFiles.isNotEmpty)
                            Column(
                              children: List.generate(_pickedFiles.length, (i) {
                                final pf = _pickedFiles[i];
                                final isImage = pf.extension != null && ['jpg', 'jpeg', 'png'].contains(pf.extension!.toLowerCase());
                                return Card(
                                  child: ListTile(
                                    leading: isImage && pf.path != null
                                        ? Image.file(File(pf.path!), width: 48, height: 48, fit: BoxFit.cover)
                                        : const Icon(Icons.picture_as_pdf, size: 40),
                                    title: Text(pf.name),
                                    subtitle: Text('${(pf.size / 1024).toStringAsFixed(1)} KB'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removePickedFile(i),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    
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