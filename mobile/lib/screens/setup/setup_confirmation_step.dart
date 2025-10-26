import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/metartpay_branding.dart';
import '../../providers/merchant_provider.dart';

class SetupConfirmationStep extends StatelessWidget {
  final Map<String, dynamic> setupData;
  final VoidCallback onComplete;
  final VoidCallback onPrevious;

  const SetupConfirmationStep({
    Key? key,
    required this.setupData,
    required this.onComplete,
    required this.onPrevious,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Almost Done!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: MetartPayColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your information before completing setup.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Business Information
                  _buildSectionCard(
                    title: 'Business Information',
                    icon: Icons.business,
                    items: [
                      _buildInfoItem('Business Name', setupData['businessName']),
                      _buildInfoItem('Industry', setupData['industry']),
                      _buildInfoItem('Contact Email', setupData['contactEmail']),
                      if (setupData['businessAddress']?.isNotEmpty == true)
                        _buildInfoItem('Business Address', setupData['businessAddress']),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Personal Information
                  _buildSectionCard(
                    title: 'Personal Information',
                    icon: Icons.person,
                    items: [
                      _buildInfoItem('Full Name', setupData['fullName']),
                      if (setupData['idNumber']?.isNotEmpty == true)
                        _buildInfoItem('ID Number', setupData['idNumber']),
                      if (setupData['bvn']?.isNotEmpty == true)
                        _buildInfoItem('BVN', _maskSensitiveData(setupData['bvn'])),
                      if (setupData['address']?.isNotEmpty == true)
                        _buildInfoItem('Address', setupData['address']),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bank Account
                  _buildSectionCard(
                    title: 'Bank Account',
                    icon: Icons.account_balance,
                    items: [
                      _buildInfoItem('Bank', setupData['bankName']),
                      _buildInfoItem('Account Number', _maskAccountNumber(setupData['bankAccountNumber'])),
                      _buildInfoItem('Account Name', setupData['bankAccountName']),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Crypto Wallets
                  _buildSectionCard(
                    title: 'Crypto Wallets',
                    icon: Icons.account_balance_wallet,
                    items: [
                      ...(setupData['walletAddresses'] as Map<String, String>? ?? {})
                          .entries
                          .map((entry) => _buildInfoItem(
                                entry.key,
                                _maskWalletAddress(entry.value),
                              )),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Welcome Message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MetartPayColors.primary.withAlpha((0.1 * 255).round()),
                          Colors.orange.withAlpha((0.1 * 255).round()),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MetartPayColors.primary.withAlpha((0.2 * 255).round())),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 48,
                          color: MetartPayColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to MetartPay!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: MetartPayColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all set to start accepting crypto payments and growing your business with MetartPay.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
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
          Consumer<MerchantProvider>(
            builder: (context, merchantProvider, child) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPrevious,
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
                      text: merchantProvider.isLoading 
                          ? 'Completing Setup...' 
                          : 'Complete Setup',
                      onPressed: merchantProvider.isLoading ? null : onComplete,
                      isGradient: false,
                      child: merchantProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MetartPayColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: MetartPayColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskSensitiveData(String? data) {
    if (data == null || data.isEmpty) return '';
    if (data.length <= 4) return '*' * data.length;
    return '${data.substring(0, 2)}${'*' * (data.length - 4)}${data.substring(data.length - 2)}';
  }

  String _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return '';
    if (accountNumber.length <= 4) return '*' * accountNumber.length;
    return '${accountNumber.substring(0, 3)}${'*' * 4}${accountNumber.substring(accountNumber.length - 3)}';
  }

  String _maskWalletAddress(String address) {
    if (address.length <= 8) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}