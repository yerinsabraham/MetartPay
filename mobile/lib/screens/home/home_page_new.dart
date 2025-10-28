import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../../utils/app_logger.dart';
import '../../widgets/home_widgets_new.dart';
import '../../widgets/metartpay_branding.dart';
import 'home_controller_new.dart';
import '../../providers/notification_provider.dart';
import '../demo_simulate_page.dart';

/// A simplified, minimal homepage (v2).
/// Keep this file separate from existing `home_screen.dart` while we validate.
class HomePageNew extends StatelessWidget {
  const HomePageNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final merchantProvider = Provider.of<MerchantProvider>(context);
    final merchant = merchantProvider.currentMerchant;

    return Scaffold(
      appBar: GradientAppBar(
        title: '',
        showLogo: true,
        plainWhiteBackground: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              final hasUnread = (notif.unreadCount ?? 0) > 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/notifications');
                    },
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          // Show only the merchant business name in the header (user requested)
                          Text(
                            merchant?.businessName ?? 'Merchant',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                      const SizedBox(height: 6),
                      if (merchant != null && (merchant.kycStatus ?? '').toLowerCase() == 'pending')
                        Text('KYC Verification Pending.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // intentionally removed old MP button (deprecated)
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Ensure merchant data is loaded when this page appears so the
                // welcome text and KYC status reflect backend state.
                Builder(builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final mp = Provider.of<MerchantProvider>(context, listen: false);
                    if (mp.currentMerchant == null && !mp.hasAttemptedLoad) {
                      mp.loadUserMerchants();
                    }
                  });
                  return const SizedBox.shrink();
                }),
              SimpleDashboard(
                merchant: merchant,
                onCreatePressed: () => HomeController.openCreatePayment(context),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: HomeShortcuts(
                  onCreate: () => HomeController.openCreatePayment(context),
                  onViewTransactions: () => HomeController.openTransactions(context),
                ),
              ),
            ],
          ),
        ),
      ),
      // Debug simulate FAB: visible only in non-production builds
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.bug_report),
              label: const Text('Simulate'),
              onPressed: () {
                // Use named route if available (only defined in debug builds via main.dart)
                try {
                  Navigator.of(context).pushNamed('/demo-simulate');
                } catch (_) {
                  // Fallback: push DemoSimulatePage directly
                  final baseUrl = const String.fromEnvironment('METARTPAY_BASE_URL', defaultValue: 'http://127.0.0.1:5001/metartpay-bac2f/us-central1/api');
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DemoSimulatePage(baseUrl: baseUrl)));
                }
              },
            )
          : null,
    );
  }
}

