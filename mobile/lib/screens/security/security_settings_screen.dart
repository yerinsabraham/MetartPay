import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import 'biometric_settings_screen.dart';
import 'session_management_screen.dart';
import 'security_logs_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  void _loadSecurityData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      securityProvider.refreshAllData(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<SecurityProvider, AuthProvider>(
        builder: (context, securityProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Please log in to access security settings'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await securityProvider.refreshAllData(authProvider.currentUser!.uid);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Security Overview Card
                _buildSecurityOverviewCard(securityProvider),
                
                const SizedBox(height: 16),
                
                // Biometric Authentication Section
                _buildBiometricSection(context, securityProvider),
                
                const SizedBox(height: 16),
                
                // Session Management Section
                _buildSessionSection(context, securityProvider),
                
                const SizedBox(height: 16),
                
                // Security Monitoring Section
                _buildMonitoringSection(context, securityProvider),
                
                const SizedBox(height: 16),
                
                // Emergency Actions Section
                _buildEmergencySection(context, securityProvider, authProvider),
                
                const SizedBox(height: 24),
                
                // Security Tips
                _buildSecurityTips(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityOverviewCard(SecurityProvider securityProvider) {
    final alertStats = securityProvider.getAlertStatistics();
    final hasAlerts = securityProvider.totalAlerts > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          Row(
            children: [
              Icon(
                hasAlerts ? Icons.warning : Icons.security,
                color: hasAlerts 
                  ? (securityProvider.hasCriticalAlerts ? Colors.red : Colors.orange)
                  : Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAlerts ? 'Security Alerts' : 'Security Status: Good',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      hasAlerts 
                        ? '${securityProvider.totalAlerts} security alert${securityProvider.totalAlerts != 1 ? 's' : ''} require attention'
                        : 'No security issues detected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasAlerts) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAlertStat('Critical', alertStats['critical']!, Colors.red),
                _buildAlertStat('High', alertStats['high']!, Colors.orange),
                _buildAlertStat('Medium', alertStats['medium']!, Colors.yellow[700]!),
                _buildAlertStat('Low', alertStats['low']!, Colors.green),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildAlertStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
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

  Widget _buildBiometricSection(BuildContext context, SecurityProvider securityProvider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Colors.blue),
            title: const Text('Biometric Authentication'),
            subtitle: Text(
              securityProvider.biometricCapability?.canUseBiometric == true
                ? 'Enhanced security with ${securityProvider.biometricCapability?.availableTypesDescription}'
                : 'Not available on this device',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BiometricSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection(BuildContext context, SecurityProvider securityProvider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.devices, color: Colors.green),
            title: const Text('Session Management'),
            subtitle: Text('${securityProvider.activeSessions.length} active session(s)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SessionManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringSection(BuildContext context, SecurityProvider securityProvider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('Security Logs'),
            subtitle: Text('${securityProvider.securityLogs.length} recent entries'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SecurityLogsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Security Notifications'),
            subtitle: const Text('Get notified of suspicious activity'),
            value: true, // This would be tied to actual settings
            onChanged: (value) {
              // Implement notification toggle
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(
    BuildContext context,
    SecurityProvider securityProvider,
    AuthProvider authProvider,
  ) {
    return Card(
      color: Colors.red[50],
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: const Text('Emergency Actions'),
            subtitle: const Text('Quick security responses'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('End All Sessions'),
            subtitle: const Text('Sign out from all devices'),
            onTap: () => _showEndAllSessionsDialog(context, securityProvider, authProvider),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.blue),
            title: const Text('Refresh Session'),
            subtitle: const Text('Generate new security token'),
            onTap: () => _refreshSession(context, securityProvider),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.red),
            title: const Text('Reset Security Settings'),
            subtitle: const Text('Clear all security configurations'),
            onTap: () => _showResetSecurityDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Security Tips',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Enable biometric authentication for enhanced security'),
              Text('• Regularly review active sessions and end unused ones'),
              Text('• Monitor security logs for suspicious activity'),
              Text('• Keep your device updated with latest security patches'),
              Text('• Use strong, unique passwords for your account'),
              Text('• Avoid accessing your account on public Wi-Fi'),
            ],
          ),
        ],
        ),
      ),
    );
  }

  void _showEndAllSessionsDialog(
    BuildContext context,
    SecurityProvider securityProvider,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End All Sessions'),
          content: const Text(
            'This will sign you out from all devices except this one. '
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  await securityProvider.endAllOtherSessions(
                    authProvider.currentUser!.uid,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All other sessions have been ended'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error ending sessions: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Sessions'),
            ),
          ],
        );
      },
    );
  }

  void _refreshSession(BuildContext context, SecurityProvider securityProvider) async {
    try {
      final success = await securityProvider.refreshCurrentSession();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'Security session refreshed successfully'
                : 'Failed to refresh session',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Security Settings'),
          content: const Text(
            'This will reset all security configurations including '
            'biometric settings, session preferences, and clear security logs. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement reset functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security settings reset functionality will be implemented'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}