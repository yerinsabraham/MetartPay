import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';
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

        // Debug: log merchantProvider state to help trace onboarding decision
        // Use debugPrint only in debug builds
        if (merchantProvider.currentMerchant != null) {
          final m = merchantProvider.currentMerchant!;
          debugPrint('DEBUG: AuthWrapper - hasAttemptedLoad=${merchantProvider.hasAttemptedLoad} isLoading=${merchantProvider.isLoading} merchantsCount=${merchantProvider.merchants.length} currentMerchant=${m.id}');
          debugPrint('DEBUG: AuthWrapper - currentMerchant: id=${m.id} fullName=${m.fullName} idNumber=${m.idNumber} kyc=${m.kycStatus} isSetup=${m.isSetupComplete}');
        } else {
          debugPrint('DEBUG: AuthWrapper - hasAttemptedLoad=${merchantProvider.hasAttemptedLoad} isLoading=${merchantProvider.isLoading} merchantsCount=${merchantProvider.merchants.length} currentMerchant=null');
        }

        // Check merchant and KYC state
        final merchant = merchantProvider.currentMerchant;
        final bool hasAnyMerchant = merchantProvider.merchants.isNotEmpty;
        final bool hasCompletedSetup = merchant?.isSetupComplete ?? false;
        final String? kycStatus = merchant?.kycStatus;

        // Consider KYC as "submitted" if there's any non-null status (pending/under-review/approved)
        final bool kycSubmitted = kycStatus != null && kycStatus.isNotEmpty;

        // Show setup wizard only when the user has no merchants OR setup isn't complete AND KYC hasn't been submitted
        if ((!hasCompletedSetup || !hasAnyMerchant) && !kycSubmitted) {
          return const MerchantSetupWizard();
        }

        // Otherwise show the main app
        return const HomeScreen();
      },
    );
  }
}