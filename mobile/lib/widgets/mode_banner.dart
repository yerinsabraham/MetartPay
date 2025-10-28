import 'package:flutter/material.dart';

/// Small runtime mode banner used on auth screens to show emulator/cloud/test flags.
class ModeBanner extends StatelessWidget {
  const ModeBanner({super.key});

  static final bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  static final bool requireEmailVerification = bool.fromEnvironment('REQUIRE_EMAIL_VERIFICATION', defaultValue: false);
  static final bool useTestData = bool.fromEnvironment('USE_TEST_DATA', defaultValue: true);

  @override
  Widget build(BuildContext context) {
    final modeLabel = useEmulator ? 'EMULATOR' : 'CLOUD';
    final modeColor = useEmulator ? Colors.orange.shade700 : Colors.green.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: modeColor.withOpacity(0.07),
        border: Border.all(color: modeColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mode: $modeLabel',
            style: TextStyle(color: modeColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            'Email verification: ${requireEmailVerification ? 'ON' : 'OFF'}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Text(
            'Test data: ${useTestData ? 'ON' : 'OFF'}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
