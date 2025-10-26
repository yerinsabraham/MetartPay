import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/merchant_provider.dart';
import '../../utils/app_logger.dart';
import '../../widgets/home_widgets_new.dart';
import '../../widgets/metartpay_branding.dart';
import 'home_controller_new.dart';

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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              AppLogger.d('DEBUG: Notifications tapped (inactive)');
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
    );
  }
}
