import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../home/home_page_new.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import 'login_screen.dart';
// Legacy HomeScreen removed — use HomePageNew (v2) as the single home entry
import '../setup/merchant_setup_wizard.dart';
import 'email_verification_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MerchantProvider>(
      builder: (context, authProvider, merchantProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // If configured to require email verification, and user is signed in but hasn't verified,
        // show the verification screen. For beta/testing we keep REQUIRE_EMAIL_VERIFICATION=false so
        // this will not block testers.
        if (AuthProvider.requireEmailVerification && authProvider.user != null && !(authProvider.user?.emailVerified ?? false)) {
          return const EmailVerificationScreen();
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

        // Show the v2 home page by default (simplified POS-first dashboard)
        return const HomePageNew();
      },
    );
  }
}