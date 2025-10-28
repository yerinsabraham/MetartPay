import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../widgets/metartpay_branding.dart';
import 'business_info_step.dart';
import 'kyc_details_step.dart';
import 'bank_account_step.dart';
// Wallet generation step intentionally omitted in Phase A setup
import 'setup_confirmation_step.dart';

class MerchantSetupWizard extends StatefulWidget {
  const MerchantSetupWizard({Key? key}) : super(key: key);

  @override
  State<MerchantSetupWizard> createState() => _MerchantSetupWizardState();
}

class _MerchantSetupWizardState extends State<MerchantSetupWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final Map<String, dynamic> _setupData = {
    'businessName': '',
    'industry': '',
    'contactEmail': '',
    'businessAddress': '',
    'fullName': '',
    'idNumber': '',
    'bvn': '',
    'address': '',
    'bankAccountNumber': '',
    'bankName': '',
    'bankAccountName': '',
    // walletAddresses removed during Phase A - wallets/QR generation deferred to later phases
  };

  final List<String> _stepTitles = [
    'Business Information',
    'Personal Details',
    'Bank Account',
    'Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final currentMerchant = merchantProvider.currentMerchant;
    
    if (currentMerchant != null) {
      setState(() {
        _setupData['businessName'] = currentMerchant.businessName;
        _setupData['industry'] = currentMerchant.industry;
        _setupData['contactEmail'] = currentMerchant.contactEmail;
        _setupData['businessAddress'] = currentMerchant.businessAddress ?? '';
        _setupData['fullName'] = currentMerchant.fullName;
        _setupData['idNumber'] = currentMerchant.idNumber ?? '';
        _setupData['bvn'] = currentMerchant.bvn ?? '';
        _setupData['address'] = currentMerchant.address ?? '';
        _setupData['bankAccountNumber'] = currentMerchant.bankAccountNumber;
        _setupData['bankName'] = currentMerchant.bankName;
        _setupData['bankAccountName'] = currentMerchant.bankAccountName;
        // walletAddresses intentionally omitted for Phase A
      });
    }
  }

  bool _isStepLoading = false;

  void _nextStep() async {
    if (_isStepLoading) return;
    if (mounted) setState(() { _isStepLoading = true; });

    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

  debugPrint('DEBUG: Auth status - isAuthenticated: ${authProvider.isAuthenticated}');
  debugPrint('DEBUG: Auth status - currentUser: ${authProvider.currentUser?.uid}');
  debugPrint('DEBUG: Setup data to save: $_setupData');

    // Show loading indicator while saving
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving progress...'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }

  // Prepare a serializable copy for partial save (exclude in-memory file objects)
  final serializableData = Map<String, dynamic>.from(_setupData);
  if (serializableData.containsKey('kycFiles')) serializableData.remove('kycFiles');

  final success = await merchantProvider.savePartialSetupData(serializableData);

    if (!success && mounted) {
  final errorMessage = merchantProvider.error ?? 'Failed to save progress. Please try again.';
  debugPrint('DEBUG: Setup save failed with error: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      if (mounted) setState(() { _isStepLoading = false; });
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
      if (mounted) {
        setState(() {
          _currentStep++;
          _isStepLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } else {
      if (mounted) setState(() { _isStepLoading = false; });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Completing setup...'),
            ],
          ),
        ),
      );
    }
    
    final success = await merchantProvider.createMerchantWithSetup(
      businessName: _setupData['businessName'],
      industry: _setupData['industry'],
      contactEmail: _setupData['contactEmail'],
      businessAddress: _setupData['businessAddress'],
      fullName: _setupData['fullName'],
      idNumber: _setupData['idNumber'],
      bvn: _setupData['bvn'],
      address: _setupData['address'],
      bankAccountNumber: _setupData['bankAccountNumber'],
      bankName: _setupData['bankName'],
      bankAccountName: _setupData['bankAccountName'],
      merchantTier: _setupData['merchantTier'],
      kycFiles: (_setupData['kycFiles'] as List<dynamic>?) ?? [],
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home screen
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${merchantProvider.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSetupData(String key, dynamic value) {
    setState(() {
      _setupData[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: MetartPayColors.primary),
                    onPressed: _previousStep,
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MetartPayColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of ${_stepTitles.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(8),
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _stepTitles.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(MetartPayColors.primary),
                  ),
                ),
              ),
            ),
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              BusinessInfoStep(
                setupData: _setupData,
                onDataUpdate: _updateSetupData,
                onNext: _nextStep,
              ),
              KYCDetailsStep(
                setupData: _setupData,
                onDataUpdate: _updateSetupData,
                onNext: _nextStep,
                onPrevious: _previousStep,
              ),
              BankAccountStep(
                setupData: _setupData,
                onDataUpdate: _updateSetupData,
                onNext: _nextStep,
                onPrevious: _previousStep,
              ),
              // Wallet generation step removed for Phase A
              SetupConfirmationStep(
                setupData: _setupData,
                onComplete: _completeSetup,
                onPrevious: _previousStep,
              ),
            ],
          ),
        ),
        if (_isStepLoading)
          Container(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}