import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../widgets/metartpay_branding.dart';
import '../wallets/crypto_wallets_screen.dart';
import '../payments/create_payment_link_screen.dart';
import '../transactions/transaction_history_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final merchantProvider = Provider.of<MerchantProvider>(
        context,
        listen: false,
      );
      if (merchantProvider.merchants.isEmpty && !merchantProvider.isLoading) {
        merchantProvider.loadUserMerchants();
      }
    });
  }

  void _showFeatureBlocked(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Text('KYC Required'),
          ],
        ),
        content: Text(
          'Complete your KYC verification to access $featureName and other features.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isKYCVerified(MerchantProvider merchantProvider) {
    return merchantProvider.currentMerchant?.kycStatus == 'verified';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Consumer<MerchantProvider>(
          builder: (context, merchantProvider, _) {
            final merchant = merchantProvider.currentMerchant;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  merchant?.businessName ?? 'Merchant',
                  style: const TextStyle(
                    fontSize: 18,
                    color: MetartPayColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: MetartPayColors.primary,
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: MetartPayColors.primary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, _) {
          if (merchantProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: MetartPayColors.primary),
                  SizedBox(height: 16),
                  Text('Loading your dashboard...'),
                ],
              ),
            );
          }

          if (merchantProvider.error != null ||
              merchantProvider.merchants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 48,
                    color: MetartPayColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('Unable to load dashboard'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => merchantProvider.loadUserMerchants(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await merchantProvider.loadUserMerchants();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KYC Completion Banner
                  if (merchantProvider.currentMerchant?.kycStatus != 'verified')
                    _buildKYCBanner(context, merchantProvider),

                  _buildMerchantCard(context, merchantProvider),
                  const SizedBox(height: 20),
                  _buildStatsCards(merchantProvider),
                  const SizedBox(height: 20),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  if (merchantProvider.invoices.isNotEmpty)
                    _buildRecentInvoicesSection(merchantProvider),
                  const SizedBox(height: 20),
                  _buildPaymentInsights(merchantProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKYCBanner(
    BuildContext context,
    MerchantProvider merchantProvider,
  ) {
    final merchant = merchantProvider.currentMerchant;
    if (merchant?.kycStatus == 'verified') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your KYC Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify your identity to access all features and start receiving payments.',
                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.red.shade400, size: 16),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(
    BuildContext context,
    MerchantProvider merchantProvider,
  ) {
    final merchant = merchantProvider.currentMerchant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MetartPayColors.primary, Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MetartPayColors.primary.withAlpha((0.3 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant?.businessName ?? 'Your Business',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      merchant?.industry ?? 'Business',
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.8 * 255).round()),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getKYCStatusText(merchant?.kycStatus ?? 'pending'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Available Balance',
                  '₦${_formatMoney(merchant?.availableBalance ?? 0)}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard(
                  'Total Balance',
                  '₦${_formatMoney(merchant?.totalBalance ?? 0)}',
                  Icons.savings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.8 * 255).round()),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(MerchantProvider merchantProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Invoices',
            '${merchantProvider.invoices.length}',
            Icons.receipt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Paid This Month',
            _getPaidInvoicesCount(merchantProvider.invoices).toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            _getPendingInvoicesCount(merchantProvider.invoices).toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Create Payment',
                Icons.payment,
                Colors.green,
                () {
                  final merchantProvider = Provider.of<MerchantProvider>(
                    context,
                    listen: false,
                  );
                  if (!_isKYCVerified(merchantProvider)) {
                    _showFeatureBlocked(context, 'Payment Creation');
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePaymentLinkScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Wallets',
                Icons.account_balance_wallet,
                Colors.blue,
                () {
                  final merchantProvider = Provider.of<MerchantProvider>(
                    context,
                    listen: false,
                  );
                  if (!_isKYCVerified(merchantProvider)) {
                    _showFeatureBlocked(context, 'Crypto Wallets');
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CryptoWalletsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Transactions',
                Icons.history,
                Colors.purple,
                () {
                  final merchantProvider = Provider.of<MerchantProvider>(
                    context,
                    listen: false,
                  );
                  if (!_isKYCVerified(merchantProvider)) {
                    _showFeatureBlocked(context, 'Transaction History');
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Analytics',
                Icons.analytics,
                Colors.orange,
                () {
                  final merchantProvider = Provider.of<MerchantProvider>(
                    context,
                    listen: false,
                  );
                  if (!_isKYCVerified(merchantProvider)) {
                    _showFeatureBlocked(context, 'Analytics');
                    return;
                  }
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoicesSection(MerchantProvider merchantProvider) {
    final recentInvoices = merchantProvider.invoices.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Invoices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentInvoices.map((invoice) => _buildInvoiceCard(invoice)),
      ],
    );
  }

  Widget _buildInvoiceCard(dynamic invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(
                invoice.status,
              ).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(invoice.status),
              color: _getStatusColor(invoice.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₦${_formatMoney(invoice.amountNaira)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(
                invoice.status,
              ).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              invoice.statusDisplayName,
              style: TextStyle(
                color: _getStatusColor(invoice.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInsights(MerchantProvider merchantProvider) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Success Rate',
            '${_calculateSuccessRate(merchantProvider.invoices)}%',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Average Amount',
            '₦${_formatMoney(_calculateAverageAmount(merchantProvider.invoices))}',
            Icons.attach_money,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'This Month',
            '${_getThisMonthCount(merchantProvider.invoices)} payments',
            Icons.calendar_today,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getKYCStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not Started';
    }
  }

  String _formatMoney(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  int _getPaidInvoicesCount(List<dynamic> invoices) {
    return invoices.where((invoice) => invoice.isPaid).length;
  }

  int _getPendingInvoicesCount(List<dynamic> invoices) {
    return invoices.where((invoice) => invoice.isPending).length;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  double _calculateSuccessRate(List<dynamic> invoices) {
    if (invoices.isEmpty) return 0.0;
    final paid = invoices.where((invoice) => invoice.isPaid).length;
    return (paid / invoices.length * 100);
  }

  double _calculateAverageAmount(List<dynamic> invoices) {
    if (invoices.isEmpty) return 0.0;
    final total = invoices.fold<double>(
      0.0,
      (sum, invoice) => sum + invoice.amountNaira,
    );
    return total / invoices.length;
  }

  int _getThisMonthCount(List<dynamic> invoices) {
    final now = DateTime.now();
    return invoices.where((invoice) {
      return invoice.createdAt.year == now.year &&
          invoice.createdAt.month == now.month;
    }).length;
  }
}
