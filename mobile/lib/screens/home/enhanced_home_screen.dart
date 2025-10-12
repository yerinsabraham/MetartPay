import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/merchant_provider.dart';
import '../../screens/kyc/kyc_verification_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/transactions/transaction_history_screen.dart';
import '../../screens/wallets/crypto_wallets_screen.dart';
// ...analytics screen import removed (unused)
import '../../screens/payment_links/create_payment_link_screen.dart';
import '../../screens/payment_links/payment_links_screen.dart';
import '../../screens/receive_payments_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantProvider>(
      builder: (context, merchantProvider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        
        return Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: Text(
              'MetartPay',
              style: TextStyle(
                // use theme primary color for branding
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.account_circle_outlined, color: colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await merchantProvider.loadUserMerchants();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildKYCBanner(context, merchantProvider),
                _buildWelcomeCard(context, merchantProvider),
                const SizedBox(height: 16),
                _buildQuickStats(context, merchantProvider),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildRecentTransactions(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKYCBanner(BuildContext context, MerchantProvider merchantProvider) {
    final merchant = merchantProvider.currentMerchant;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Don't show banner if KYC is verified
    if (merchant?.kycStatus == 'verified') return const SizedBox.shrink();
    
    // Check if KYC has been submitted (has fullName, idNumber, etc.)
    final bool hasSubmittedKYC = merchant != null &&
        merchant.fullName.isNotEmpty &&
        merchant.idNumber != null &&
        merchant.idNumber!.isNotEmpty;
    
    // If KYC has been submitted and is pending, show "pending confirmation"
    if (hasSubmittedKYC && merchant.kycStatus == 'pending') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.pending,
                color: colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Verification Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your KYC verification is under review. We\'ll notify you within 24-48 hours.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // If KYC hasn't been submitted yet, show "complete KYC" banner
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KYCVerificationScreen(),
          ),
        );
      },
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          border: Border.all(color: colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your KYC Verification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verify your identity to access all features and start receiving payments.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.error,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, MerchantProvider merchantProvider) {
    final merchant = merchantProvider.currentMerchant;
    final businessName = merchant?.businessName ?? 'Your Business';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onPrimary.withAlpha((0.08 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: TextStyle(
              color: colorScheme.onPrimary.withAlpha((0.9 * 255).round()),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            businessName,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Balance', '₦0.00', Icons.account_balance_wallet),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('This Month', '₦0.00', Icons.trending_up),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
  color: colorScheme.onPrimary.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.onPrimary, size: 18),
              const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withAlpha((0.9 * 255).round()),
                      fontSize: 12,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, MerchantProvider merchantProvider) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: _buildQuickStatCard('Transactions', '0', Icons.receipt_long, cs.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickStatCard('Customers', '0', Icons.people, cs.secondary)),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickStatCard('Revenue', '₦0.00', Icons.monetization_on, cs.tertiary)),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withAlpha((0.06 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxis = 2;
            final width = constraints.maxWidth;
            if (width > 900) {
              crossAxis = 4;
            } else if (width > 600) {
              crossAxis = 3;
            }

            return GridView.count(
              crossAxisCount: crossAxis,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildActionCard(
                  'Receive Payments',
                  Icons.qr_code,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceivePaymentsScreen(
                        merchantId: Provider.of<MerchantProvider>(context, listen: false).currentMerchant?.id ?? 'demo_merchant',
                      ),
                    ),
                  ),
                ),
                _buildActionCard(
                  'Create Payment Link',
                  Icons.add_link,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreatePaymentLinkScreen()),
                  ),
                ),
                _buildActionCard(
                  'Payment Links',
                  Icons.link,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentLinksScreen()),
                  ),
                ),
                _buildActionCard(
                  'View Wallets',
                  Icons.account_balance_wallet,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CryptoWalletsScreen()),
                  ),
                ),
                _buildActionCard(
                  'Transactions',
                  Icons.receipt_long,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.06 * 255).round()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your recent transactions will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.9 * 255).round()),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}