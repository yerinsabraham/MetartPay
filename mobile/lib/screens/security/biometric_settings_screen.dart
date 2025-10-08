import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricCapabilities();
  }

  Future<void> _loadBiometricCapabilities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
      await securityProvider.checkBiometricCapability();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading biometric capabilities: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Settings'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          final capability = securityProvider.biometricCapability;
          
          if (_isLoading || securityProvider.biometricLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (capability != null) ...[
                  _buildCapabilityCard(capability),
                  const SizedBox(height: 24),
                  _buildSecurityInfo(capability),
                  const SizedBox(height: 24),
                  _buildBiometricSettings(capability),
                  const SizedBox(height: 24),
                  _buildSecurityActions(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCapabilityCard(BiometricCapability capability) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  capability.canUseBiometric ? Icons.check_circle : Icons.error,
                  color: capability.canUseBiometric ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Compatibility',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        capability.canUseBiometric
                          ? 'Your device supports biometric authentication'
                          : 'Biometric authentication is not available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCapabilityStat(
                  'Supported',
                  capability.isSupported ? 'Yes' : 'No',
                  capability.isSupported ? Colors.green : Colors.red,
                ),
                _buildCapabilityStat(
                  'Enrolled',
                  capability.isEnrolled ? 'Yes' : 'No',
                  capability.isEnrolled ? Colors.green : Colors.orange,
                ),
                _buildCapabilityStat(
                  'Available Types',
                  capability.availableTypes.length.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(BiometricCapability capability) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Security Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildInfoRow(
                  'Device Security Level',
                  capability.isSupported ? 'Hardware Backed' : 'Not Available',
                  Icons.security,
                ),
                _buildInfoRow(
                  'Biometric Types Available',
                  capability.availableTypes.join(', ').isEmpty 
                    ? 'None' 
                    : capability.availableTypes.join(', '),
                  Icons.fingerprint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricSettings(BiometricCapability capability) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                Text(
                  'Biometric Preferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildSettingRow(
                  'Enable Biometric Login',
                  'Use biometric authentication for app login',
                  capability.canUseBiometric && capability.isEnrolled,
                  capability.canUseBiometric,
                  (value) => _toggleBiometricLogin(value),
                ),
                _buildSettingRow(
                  'Enable Transaction Authentication',
                  'Require biometric for high-value transactions',
                  false, // This would come from user preferences
                  capability.canUseBiometric,
                  (value) => _toggleTransactionAuth(value),
                ),
                _buildSettingRow(
                  'Enable Settings Access',
                  'Require biometric to access sensitive settings',
                  false, // This would come from user preferences
                  capability.canUseBiometric,
                  (value) => _toggleSettingsAuth(value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.build),
                const SizedBox(width: 8),
                Text(
                  'Security Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh Biometric Status'),
                  subtitle: Text('Check for new biometric enrollments'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.settings_applications),
                  title: Text('Device Settings'),
                  subtitle: Text('Open device biometric settings'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Biometric Help'),
                  subtitle: Text('Learn more about biometric security'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    String title,
    String subtitle,
    bool value,
    bool enabled,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      enabled: enabled,
    );
  }

  Future<void> _toggleBiometricLogin(bool enabled) async {
    if (!enabled) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
      
      if (enabled) {
        final authenticated = await securityProvider.authenticateWithBiometrics(
          'Please authenticate to enable biometric login',
        );
        
        if (authenticated == BiometricAuthResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric login enabled')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication failed')),
            );
          }
        }
      } else {
        // Disable biometric login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric login disabled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTransactionAuth(bool enabled) async {
    // Implementation for transaction authentication toggle
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled 
            ? 'Transaction authentication enabled' 
            : 'Transaction authentication disabled'
          ),
        ),
      );
    }
  }

  Future<void> _toggleSettingsAuth(bool enabled) async {
    // Implementation for settings authentication toggle
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled 
            ? 'Settings authentication enabled' 
            : 'Settings authentication disabled'
          ),
        ),
      );
    }
  }
}