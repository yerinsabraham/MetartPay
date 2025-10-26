import 'package:flutter/material.dart';
// removed unused import
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../providers/merchant_provider.dart';
// removed unused import
import '../../widgets/metartpay_branding.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;

  // Controllers for business info
  final _businessNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();

  // Controllers for wallet addresses
  final _ethereumAddressController = TextEditingController();
  final _bscAddressController = TextEditingController();
  final _polygonAddressController = TextEditingController();
  final _tronAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMerchantData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _ethereumAddressController.dispose();
    _bscAddressController.dispose();
    _polygonAddressController.dispose();
    _tronAddressController.dispose();
    super.dispose();
  }

  void _loadMerchantData() {
    final merchantProvider = context.read<MerchantProvider>();
    final merchant = merchantProvider.currentMerchant;

    if (merchant != null) {
      _businessNameController.text = merchant.businessName;
      _bankAccountController.text = merchant.bankAccountNumber;
      _bankNameController.text = merchant.bankName;
      _bankAccountNameController.text = merchant.bankAccountName;
    }
  }

  Future<void> _saveBusinessInfo() async {
    // TODO: Implement business info update API
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business information updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveWalletAddresses() async {
    // TODO: Implement wallet addresses update API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet addresses updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final merchantProvider = context.watch<MerchantProvider>();

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Merchant Profile',
        actions: [
          if (_tabController.index == 0)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _loadMerchantData(); // Reset if canceling edit
                  }
                });
              },
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: Colors.white,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Business'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallets'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessTab(merchantProvider),
          _buildWalletsTab(),
          _buildSettingsTab(authProvider),
        ],
      ),
    );
  }

  Widget _buildBusinessTab(MerchantProvider merchantProvider) {
    final merchant = merchantProvider.currentMerchant;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.business,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    merchant?.businessName ?? 'Business Name',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getKycStatusColor(
                        merchant?.kycStatus ?? 'pending',
                      ).withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getKycStatusText(merchant?.kycStatus ?? 'pending'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getKycStatusColor(
                          merchant?.kycStatus ?? 'pending',
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Business Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Business Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                });
                                _loadMerchantData();
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            MetartPayButton(
                              onPressed: _saveBusinessInfo,
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Business Name
                  _InfoField(
                    label: 'Business Name',
                    controller: _businessNameController,
                    isEditing: _isEditing,
                    icon: Icons.business,
                  ),

                  const SizedBox(height: 16),

                  // Bank Account Number
                  _InfoField(
                    label: 'Bank Account Number',
                    controller: _bankAccountController,
                    isEditing: _isEditing,
                    icon: Icons.account_balance,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 16),

                  // Bank Name
                  _InfoField(
                    label: 'Bank Name',
                    controller: _bankNameController,
                    isEditing: _isEditing,
                    icon: Icons.account_balance,
                  ),

                  const SizedBox(height: 16),

                  // Account Name
                  _InfoField(
                    label: 'Account Name',
                    controller: _bankAccountNameController,
                    isEditing: _isEditing,
                    icon: Icons.person,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Statistics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          title: 'Total Revenue',
                          value:
                              '₦${merchantProvider.totalRevenue.toStringAsFixed(2)}',
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatItem(
                          title: 'Total Invoices',
                          value: '${merchantProvider.invoices.length}',
                          icon: Icons.receipt,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          title: 'Pending',
                          value:
                              '₦${merchantProvider.totalPendingAmount.toStringAsFixed(2)}',
                          icon: Icons.schedule,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatItem(
                          title: 'Success Rate',
                          value:
                              '${((merchantProvider.paidInvoices.length / (merchantProvider.invoices.isEmpty ? 1 : merchantProvider.invoices.length)) * 100).toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wallet Addresses',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure your wallet addresses for different blockchain networks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.7 * 255).round(),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Ethereum Wallet
          _WalletAddressCard(
            title: 'Ethereum (ETH)',
            subtitle: 'ERC-20 tokens: USDT, USDC, etc.',
            icon: '⟠',
            controller: _ethereumAddressController,
            placeholder: '0x1234...5678',
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // BSC Wallet
          _WalletAddressCard(
            title: 'Binance Smart Chain (BSC)',
            subtitle: 'BEP-20 tokens: USDT, BUSD, etc.',
            icon: '🔶',
            controller: _bscAddressController,
            placeholder: '0x1234...5678',
            color: Colors.amber,
          ),

          const SizedBox(height: 16),

          // Polygon Wallet
          _WalletAddressCard(
            title: 'Polygon (MATIC)',
            subtitle: 'Polygon tokens: USDT, USDC, etc.',
            icon: '🔷',
            controller: _polygonAddressController,
            placeholder: '0x1234...5678',
            color: Colors.purple,
          ),

          const SizedBox(height: 16),

          // Tron Wallet
          _WalletAddressCard(
            title: 'Tron (TRX)',
            subtitle: 'TRC-20 tokens: USDT, etc.',
            icon: '🔴',
            controller: _tronAddressController,
            placeholder: 'T1234...5678',
            color: Colors.red,
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            height: 50,
            child: MetartPayButton(
              onPressed: _saveWalletAddresses,
              child: const Text(
                'Save Wallet Addresses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AuthProvider authProvider) {
    final theme = Theme.of(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.7 * 255).round(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Settings Options
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage payment alerts',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: '2FA, password settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Security settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.api,
                  title: 'API Settings',
                  subtitle: 'Webhooks, API keys',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Contact support, documentation',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support - Coming Soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      MetartPayButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await authProvider.signOut();
                  // Navigate back to login screen after logout
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (ctx) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getKycStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getKycStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InfoField({
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            filled: !isEditing,
            fillColor: isEditing
                ? null
                : theme.colorScheme.surfaceContainerHighest.withAlpha(
                    (0.3 * 255).round(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _WalletAddressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final TextEditingController controller;
  final String placeholder;
  final Color color;

  const _WalletAddressCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.controller,
    required this.placeholder,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.7 * 255).round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // TODO: Implement QR code scanner
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR Scanner - Coming Soon')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
