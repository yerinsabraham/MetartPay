import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'metartpay_branding.dart';
import '../services/firebase_service.dart';
import '../utils/app_logger.dart';
import '../providers/merchant_provider.dart';
import '../services/payment_service.dart';
import '../utils/app_config.dart';
import '../screens/payment_status_screen.dart';

// Non-custodial Home V2 widgets
class HomeShortcuts extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onViewTransactions;

  const HomeShortcuts({
    super.key,
    required this.onCreate,
    required this.onViewTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;

        return GridView.count(
          crossAxisCount: isWide ? 2 : 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          // Make tiles square (width == height)
          childAspectRatio: 1,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _actionCard(
              context,
              icon: Icons.qr_code_scanner,
              label: 'Create Payment',
              onTap: onCreate,
            ),
            _actionCard(
              context,
              icon: Icons.receipt_long,
              label: 'View Transactions',
              onTap: onViewTransactions,
            ),
            if (kDebugMode)
              _actionCard(
                context,
                icon: Icons.bug_report,
                label: 'Simulate Payment (debug)',
                onTap: () async {
                  // Quick simulate: create a synthetic payment via PaymentService
                  final mp = Provider.of<MerchantProvider>(context, listen: false);
                  final merchantId = mp.currentMerchant?.id;
                  if (merchantId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No merchant available to simulate for')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final svc = PaymentService(baseUrl: AppConfig.backendBaseUrl);
                    final payload = {
                      'txHash': 'SIM_Q_${DateTime.now().millisecondsSinceEpoch}',
                      'toAddress': 'simulated-address-1',
                      'fromAddress': 'simulated-sender',
                      'amountCrypto': 0.25,
                      'cryptoCurrency': 'ETH',
                      'network': 'sepolia',
                      'merchantId': merchantId,
                      'paymentLinkId': '',
                    };
                    final txId = await svc.createPayment(payload, simulateKey: AppConfig.devSimulateKey);
                    Navigator.of(context).pop(); // dismiss progress
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Simulated transaction: $txId')),
                    );
                    // Open payment status to inspect
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentStatusScreen(transactionId: txId, baseUrl: AppConfig.backendBaseUrl),
                      ),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    AppLogger.e('Quick simulate failed: $e', error: e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Simulate failed: $e')),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    // Square tile, no shadow. Use thin gray border instead of elevation.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MetartPayColors.primaryBorder60, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha((0.06 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleDashboard extends StatefulWidget {
  final dynamic merchant;
  final VoidCallback onCreatePressed;

  const SimpleDashboard({
    super.key,
    this.merchant,
    required this.onCreatePressed,
  });

  @override
  State<SimpleDashboard> createState() => _SimpleDashboardState();
}

class _SimpleDashboardState extends State<SimpleDashboard> {
  double _todaysSales = 0.0;
  double _settledToday = 0.0;
  String _cryptoReceived = '0.0';
  bool _loading = true;
  VoidCallback? _merchantListener;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();

    // Add a listener to MerchantProvider so analytics refresh when
    // transactions/invoices/merchant change in realtime.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final mp = Provider.of<MerchantProvider>(context, listen: false);
        _merchantListener = () async {
          // Reload analytics when provider notifies
          await _loadAnalytics();
        };
        mp.addListener(_merchantListener!);
      } catch (e) {
        AppLogger.w('Failed to attach MerchantProvider listener: $e', error: e);
      }
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final merchantId = widget.merchant?.id;
      if (merchantId == null) {
        setState(() {
          _todaysSales = 0.0;
          _settledToday = 0.0;
          _cryptoReceived = '0.0';
        });
        return;
      }

      final svc = FirebaseService();
      final analytics = await svc.getMerchantAnalytics(
        merchantId,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      setState(() {
        _todaysSales = (analytics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        _settledToday =
            (analytics['recentTransactions'] as List?)?.fold<double>(0.0, (
              sum,
              t,
            ) {
              final map = t as Map<String, dynamic>;
              return sum + ((map['amountNaira'] as num?)?.toDouble() ?? 0.0);
            }) ??
            0.0;
        _cryptoReceived =
            analytics['recentTransactions'] != null &&
                (analytics['recentTransactions'] as List).isNotEmpty
            ? '${((analytics['recentTransactions'] as List).first['amountCrypto'] ?? 0.0).toString()} ${((analytics['recentTransactions'] as List).first['cryptoSymbol'] ?? '')}'
            : '0.0';
      });
    } catch (e) {
      AppLogger.e('Failed to load analytics: $e', error: e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      // Merchant Overview now uses the brand gradient as background
      decoration: BoxDecoration(
        gradient: MetartPayColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MetartPayColors.primaryBorder60, width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Sale should be white on the gradient
          Text(
            "Today's Sales",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          _loading
              ? const SizedBox(
                  height: 36,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Text(
                  '₦${_todaysSales.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 8),
          // Use a lighter contrasting color for the secondary pieces of text
          Text(
            'Settled: ₦${_settledToday.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if ((_todaysSales - _settledToday) > 0)
            Text(
              'Pending Conversion: ₦${(_todaysSales - _settledToday).toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          Text(
            'Crypto Received: $_cryptoReceived | Auto Converted: ₦${_settledToday.toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove merchant provider listener if attached
    try {
      final mp = Provider.of<MerchantProvider>(context, listen: false);
      if (_merchantListener != null) mp.removeListener(_merchantListener!);
    } catch (_) {}

    super.dispose();
  }
}
