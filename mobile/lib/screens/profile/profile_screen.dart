import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/metartpay_branding.dart';
import '../kyc/kyc_verification_screen.dart';
import '../security/security_settings_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Try to ensure merchant data is loaded when opening profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = Provider.of<MerchantProvider>(context, listen: false);
      if (mp.currentMerchant == null && !mp.hasAttemptedLoad) {
        mp.loadUserMerchants();
      }
      // Also initialize notifications for current merchant if available
      final np = Provider.of<NotificationProvider>(context, listen: false);
      if (mp.currentMerchant != null) {
        np.initialize(mp.currentMerchant!.id);
      }
    });
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
          'Profile',
          style: TextStyle(
            color: MetartPayColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, _) {
          final merchant = merchantProvider.currentMerchant;
          
          if (merchant == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No profile information available'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(merchant),
                const SizedBox(height: 24),
                
                // Personal Information Section
                _buildPersonalInfoSection(merchant),
                const SizedBox(height: 16),
                
                // Business Information Section
                _buildBusinessInfoSection(merchant),
                const SizedBox(height: 16),
                
                // Account & Security Section
                _buildAccountSecuritySection(context, merchant, Provider.of<AuthProvider>(context).isAdmin),
                const SizedBox(height: 16),
                
                // Support & Help Section
                _buildSupportSection(context),
                const SizedBox(height: 16),
                
                // App Information Section
                _buildAppInfoSection(context),
                const SizedBox(height: 24),
                
                // Logout Button
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(merchant) {
    return Container(
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
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MetartPayColors.primary, Color(0xFF1E3A8A)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(merchant.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Name and Business
          Text(
            merchant.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            merchant.businessName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          
          // KYC Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getKYCStatusColor(merchant.kycStatus).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getKYCStatusColor(merchant.kycStatus),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getKYCStatusIcon(merchant.kycStatus),
                  size: 16,
                  color: _getKYCStatusColor(merchant.kycStatus),
                ),
                const SizedBox(width: 6),
                Text(
                  _getKYCStatusText(merchant.kycStatus),
                  style: TextStyle(
                    color: _getKYCStatusColor(merchant.kycStatus),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(merchant) {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Full Name', merchant.fullName),
        if (merchant.idNumber != null && merchant.idNumber!.isNotEmpty)
          _buildInfoRow('ID Number', merchant.idNumber!),
        if (merchant.bvn != null && merchant.bvn!.isNotEmpty)
          _buildInfoRow('BVN', _maskBVN(merchant.bvn!)),
        if (merchant.address != null && merchant.address!.isNotEmpty)
          _buildInfoRow('Address', merchant.address!),
        if (merchant.contactEmail.isNotEmpty)
          _buildInfoRow('Email', merchant.contactEmail),
      ],
    );
  }

  Widget _buildBusinessInfoSection(merchant) {
    return _buildSection(
      title: 'Business Information',
      icon: Icons.business_outlined,
      children: [
        _buildInfoRow('Business Name', merchant.businessName),
        if (merchant.industry.isNotEmpty)
          _buildInfoRow('Industry', merchant.industry),
        if (merchant.businessAddress != null && merchant.businessAddress!.isNotEmpty)
          _buildInfoRow('Business Address', merchant.businessAddress!),
      ],
    );
  }

  Widget _buildAccountSecuritySection(BuildContext context, merchant, bool isAdmin) {
    return _buildSection(
      title: 'Account & Security',
      icon: Icons.security_outlined,
      children: [
        _buildActionRow(
          'Security Settings',
          'Biometrics, sessions & logs',
          Icons.shield,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecuritySettingsScreen(),
              ),
            );
          },
        ),
        _buildActionRow(
          'KYC Verification',
          _getKYCStatusText(merchant.kycStatus),
          Icons.verified_user,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KYCVerificationScreen(),
              ),
            );
          },
        ),
        if (isAdmin)
          _buildActionRow(
            'Admin Dashboard',
            'Manage KYC & users',
            Icons.admin_panel_settings,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
          ),
        _buildInfoRow('Account Created', _formatDate(merchant.createdAt)),
        _buildInfoRow('Last Updated', _formatDate(merchant.updatedAt)),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildSection(
      title: 'Support & Help',
      icon: Icons.help_outline,
      children: [
        _buildActionRow(
          'Help Center',
          'Get support and answers',
          Icons.help_center_outlined,
          () {
            _showHelpCenter(context);
          },
        ),
        _buildActionRow(
          'Contact Support',
          'Reach out to our team',
          Icons.support_agent,
          () {
            _showContactSupport(context);
          },
        ),
        _buildActionRow(
          'Report Issue',
          'Report a problem',
          Icons.report_problem_outlined,
          () {
            _showReportIssue(context);
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return _buildSection(
      title: 'App Information',
      icon: Icons.info_outline,
      children: [
        _buildActionRow(
          'Privacy Policy',
          'View privacy policy',
          Icons.privacy_tip_outlined,
          () {
            _showPrivacyPolicy(context);
          },
        ),
        _buildActionRow(
          'Terms of Service',
          'View terms of service',
          Icons.description_outlined,
          () {
            _showTermsOfService(context);
          },
        ),
        _buildInfoRow('App Version', '1.0.0'),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: MetartPayColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: MetartPayColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _showLogoutDialog(context);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getInitials(String name) {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  Color _getKYCStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'under-review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  IconData _getKYCStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'under-review':
        return Icons.schedule;
      case 'rejected':
        return Icons.error;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getKYCStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'under-review':
        return 'Under Review';
      case 'rejected':
        return 'Needs Update';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String _maskBVN(String bvn) {
    if (bvn.length <= 4) return bvn;
    final visibleDigits = bvn.substring(bvn.length - 4);
    final maskedDigits = '*' * (bvn.length - 4);
    return '$maskedDigits$visibleDigits';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Dialog methods
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture locals that depend on context before async gaps
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // Close the confirmation dialog
              try {
                navigator.pop();
              } catch (_) {}

              // Show a non-dismissible progress dialog while signing out
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                );
              }

              try {
                await authProvider.signOut();

                // Dismiss progress dialog and navigate to login if still mounted
                if (mounted) {
                  try {
                    navigator.pop();
                  } catch (_) {}

                  navigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                // Dismiss progress dialog if visible
                if (mounted) {
                  try {
                    navigator.pop();
                  } catch (_) {}

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📚 Getting Started Guide'),
            SizedBox(height: 8),
            Text('💳 How to Accept Payments'),
            SizedBox(height: 8),
            Text('🔐 Account Security'),
            SizedBox(height: 8),
            Text('🔄 KYC Verification Process'),
            SizedBox(height: 8),
            Text('💰 Wallet Management'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: support@metartpay.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +234 800 METART (638278)'),
            SizedBox(height: 8),
            Text('💬 Live Chat: Available 9AM - 6PM WAT'),
            SizedBox(height: 8),
            Text('🐦 Twitter: @MetartPaySupport'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue you encountered:'),
            SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your issue here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue reported successfully. We\'ll get back to you soon.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'MetartPay Privacy Policy\n\n'
            'We are committed to protecting your privacy and personal data. '
            'This policy explains how we collect, use, and protect your information when you use our services.\n\n'
            'Information We Collect:\n'
            '• Personal identification information\n'
            '• Financial and transaction data\n'
            '• Device and usage information\n\n'
            'How We Use Your Information:\n'
            '• To provide and improve our services\n'
            '• To comply with legal requirements\n'
            '• To prevent fraud and enhance security\n\n'
            'For complete details, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'MetartPay Terms of Service\n\n'
            'By using MetartPay, you agree to these terms and conditions.\n\n'
            'Service Description:\n'
            '• MetartPay provides cryptocurrency payment processing services\n'
            '• We facilitate the conversion of crypto to fiat currency\n'
            '• All transactions are subject to our fees and policies\n\n'
            'User Responsibilities:\n'
            '• Provide accurate information during KYC\n'
            '• Comply with applicable laws and regulations\n'
            '• Secure your account credentials\n\n'
            'For complete terms, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}