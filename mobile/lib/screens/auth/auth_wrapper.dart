import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import 'login_screen.dart';
import '../home/enhanced_home_screen.dart';
import '../setup/merchant_setup_wizard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MerchantProvider>(
      builder: (context, authProvider, merchantProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Always trigger merchant data load if not already attempted
        if (!merchantProvider.hasAttemptedLoad && !merchantProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            merchantProvider.loadUserMerchants();
          });
        }

        // Show loading indicator while merchant data is loading (but NOT during setup wizard)
        if (!merchantProvider.hasAttemptedLoad) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user has completed merchant setup and KYC status
        final merchant = merchantProvider.currentMerchant;
        final bool hasAnyMerchant = merchantProvider.merchants.isNotEmpty;
        final bool hasCompletedSetup = merchant?.isSetupComplete ?? false;
        final String? kycStatus = merchant?.kycStatus;

        // If user is authenticated but hasn't completed setup, show wizard
        // BUT skip setup if KYC is pending or approved
        final bool kycIsDone = kycStatus == 'pending' || kycStatus == 'approved';
        if ((!hasCompletedSetup || !hasAnyMerchant) && !kycIsDone) {
          return const MerchantSetupWizard();
        }

        // If setup is complete or KYC is pending/approved, show the main app
        return const EnhancedHomeScreen();
      },
    );
  }
}