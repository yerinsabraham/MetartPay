import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../profile/profile_screen.dart';
import '../payment_links/create_payment_link_screen.dart';
import '../wallets/crypto_wallets_screen.dart';
import '../transactions/transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllRecent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetartPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: go to notifications
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Consumer<MerchantProvider>(builder: (context, merchantProvider, _) {
        if (merchantProvider.isLoading && !merchantProvider.hasAttemptedLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        final merchant = merchantProvider.currentMerchant;

        if (merchant == null) {
          return _EmptyMerchantView(onCreate: () => Navigator.pushNamed(context, '/setup'));
        }

  // snapshot numbers are read inside the sub-widgets when needed

      return RefreshIndicator(
          onRefresh: () async => merchantProvider.loadUserMerchants(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: solid brand fill without visible white border/margin
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _HeaderSection(merchantName: merchant.businessName, kycStatus: merchant.kycStatus),
                ),
                const SizedBox(height: 12),

                // Quick actions should appear immediately under the welcome header
                _QuickActionsRow(
                      onCreatePayment: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePaymentLinkScreen())),
                      onWallets: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CryptoWalletsScreen())),
                      onTransactions: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen())),
                    ),

                // Snapshot / metrics
                _SnapshotSection(merchantProvider: merchantProvider),

                const SizedBox(height: 16),
                // Recent payments with progressive disclosure (single source)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            TextButton(
                              onPressed: () => setState(() => _showAllRecent = !_showAllRecent),
                              child: Text(_showAllRecent ? 'Show less' : 'Show more'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._buildRecentList(merchantProvider, showAll: _showAllRecent, context: context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildRecentList(MerchantProvider provider, {required bool showAll, required BuildContext context}) {
    final recent = provider.invoices;
    final items = showAll ? recent : recent.take(3).toList();

    if (items.isEmpty) return [const Padding(padding: EdgeInsets.all(8.0), child: Text('No recent payments'))];

    return items.map((invoice) => ListTile(
      dense: true,
      leading: CircleAvatar(backgroundColor: invoice.isPaid ? Colors.green : Colors.orange, child: Icon(invoice.isPaid ? Icons.check : Icons.access_time, color: Colors.white)),
      title: Text('₦${invoice.amountNaira.toStringAsFixed(2)}'),
      subtitle: Text('${invoice.chainDisplayName} • ${invoice.statusDisplayName}'),
      trailing: Text(_relativeDate(invoice.createdAt)),
      onTap: () => Navigator.pushNamed(context, '/invoice', arguments: invoice.id),
    )).toList();
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

}
class _HeaderSection extends StatelessWidget {
  final String merchantName;
  final String kycStatus;

  const _HeaderSection({required this.merchantName, required this.kycStatus, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = kycStatus.toLowerCase();
    final showPending = status == 'pending';
    final showNotVerified = status == 'not verified' || status == 'not_verified' || status == 'not-verified' || status == 'unverified';
    final brand = Theme.of(context).colorScheme.onPrimary == Colors.white ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              merchantName.isNotEmpty ? merchantName[0].toUpperCase() : '?',
              style: TextStyle(color: brand, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
                Text(merchantName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          if (showPending || showNotVerified) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(showPending ? Icons.info_outline : Icons.error_outline, color: Colors.orangeAccent.shade200),
                const SizedBox(height: 4),
                Text(showPending ? 'KYC Pending' : 'KYC Not Verified', style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  final MerchantProvider merchantProvider;

  const _SnapshotSection({required this.merchantProvider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final processed = merchantProvider.totalRevenue;
    final settled = merchantProvider.currentMerchant?.availableBalance ?? 0.0;
    final pending = merchantProvider.totalPendingAmount;
    // Show lightweight skeletons when loading (flat)
    if (merchantProvider.isLoading) {
      return Row(
        children: [
          Expanded(child: Container(height: 72, color: Colors.grey.shade200, margin: const EdgeInsets.only(right: 12))),
          Expanded(child: Container(height: 72, color: Colors.grey.shade200, margin: const EdgeInsets.only(right: 12))),
          Expanded(child: Container(height: 72, color: Colors.grey.shade200)),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 520;
      final metricWidgets = [
        _MetricCard(
          title: 'Processed (month)',
          amount: processed,
          icon: Icons.trending_up,
          color: Colors.blue,
          tooltip: 'Total processed payments for the current month',
          onTap: () => Navigator.pushNamed(context, '/analytics', arguments: {'range': 'month'}),
        ),
        _MetricCard(
          title: 'Settled / Available',
          amount: settled,
          icon: Icons.account_balance,
          color: Colors.green,
          tooltip: 'Funds settled and available to withdraw',
          onTap: () => Navigator.pushNamed(context, '/withdraw'),
        ),
        _MetricCard(
          title: 'Pending / In Transit',
          amount: pending,
          icon: Icons.pending,
          color: Colors.orange,
          tooltip: 'Payments in transit or awaiting confirmation',
          onTap: () => Navigator.pushNamed(context, '/transactions', arguments: {'filter': 'pending'}),
        ),
      ];

      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < metricWidgets.length; i++) ...[
              metricWidgets[i],
              if (i != metricWidgets.length - 1) const SizedBox(height: 8),
            ],
            // remove duplicate Create Payment button here; primary CTA is in quick actions above
            const SizedBox(height: 12),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: metricWidgets[0]),
              const SizedBox(width: 12),
              Expanded(child: metricWidgets[1]),
              const SizedBox(width: 12),
              Expanded(child: metricWidgets[2]),
            ],
          ),
          const SizedBox(height: 12),
          // Remove the redundant Create Payment CTA here; quick actions provide the primary Create flow
        ],
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _MetricCard({required this.title, required this.amount, required this.icon, required this.color, required this.tooltip, this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.surface),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Tooltip(message: tooltip, child: const Icon(Icons.help_outline, size: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text('₦${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card);
    }

    return card;
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onCreatePayment;
  final VoidCallback onWallets;
  final VoidCallback onTransactions;

  const _QuickActionsRow({required this.onCreatePayment, required this.onWallets, required this.onTransactions, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Row of 3 flat action buttons with subtle border for a flat, card-like look
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.04 * 255).round())),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FlatActionButton(icon: Icons.add, label: 'Create\nPayment Link', onTap: onCreatePayment, tooltip: 'Generate a payment link or QR code'),
            _FlatActionButton(icon: Icons.account_balance_wallet, label: 'Wallet\nAddresses', onTap: onWallets, tooltip: 'View crypto addresses for direct deposits'),
            _FlatActionButton(icon: Icons.history, label: 'History', onTap: onTransactions, tooltip: 'View transaction history'),
          ],
        ),
      ),
    );
  }
}

class _FlatActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;

  const _FlatActionButton({required this.icon, required this.label, required this.onTap, this.tooltip, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Expanded(child: Tooltip(message: tooltip!, child: child));
    }

    return Expanded(child: child);
  }
}

// Old action item/button types removed; new flat actions are used above.

// Insights and FooterInfo removed for a cleaner, focused home screen per design guidance.

class _EmptyMerchantView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyMerchantView({required this.onCreate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 84, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No merchant selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Create a merchant account to start accepting payments', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onCreate, child: const Text('Create Merchant')),
          ],
        ),
      ),
    );
  }
}