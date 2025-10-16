import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';

/// New simplified Home V2 screen (clean, minimal)
class HomePageV2 extends StatelessWidget {
  const HomePageV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final merchantProvider = Provider.of<MerchantProvider>(context);
    final merchant = merchantProvider.currentMerchant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MetartPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreeting(merchant),
              const SizedBox(height: 12),
              _buildBalanceCard(context, merchant),
              const SizedBox(height: 16),
              _buildActionRow(context),
              const SizedBox(height: 16),
              Expanded(child: _buildRecentPayments(context)),
              const SizedBox(height: 8),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(dynamic merchant) {
    final name = merchant?.businessName ?? 'Business';
    final kyc = merchant?.kycStatus?.toLowerCase();
    Widget? badge;
    if (kyc == null || kyc.isEmpty || kyc == 'not verified' || kyc == 'not_verified') {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
        child: const Text('Verify your account', style: TextStyle(color: Colors.black87, fontSize: 12)),
      );
    } else if (kyc == 'pending') {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Text('KYC Pending', style: TextStyle(color: Colors.black87, fontSize: 12)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, dynamic merchant) {
    final balance = merchant?.availableBalance ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('₦${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Updated in real time after each payment.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: trigger balance refresh via provider/service
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    // Single horizontal row with 4 actions
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(context, icon: Icons.add, label: 'Create Payment', onTap: () => Navigator.pushNamed(context, '/create-payment-v2')),
        _actionButton(context, icon: Icons.account_balance_wallet, label: 'View Wallets', onTap: () => Navigator.pushNamed(context, '/wallets')),
        _actionButton(context, icon: Icons.attach_money, label: 'Withdraw', onTap: () => Navigator.pushNamed(context, '/withdraw')),
        _actionButton(context, icon: Icons.history, label: 'History', onTap: () => Navigator.pushNamed(context, '/transactions')),
      ],
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final width = (MediaQuery.of(context).size.width - 64) / 4;
    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[200]!)),
          backgroundColor: Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments(BuildContext context) {
    // Minimal stub for recent payments; hooking to provider/Firestore later
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/transactions'), child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: const [
              ListTile(title: Text('No payments yet — create your first payment above.'),),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('MetartPay — powered by Veinozz Fintech', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Text('v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
