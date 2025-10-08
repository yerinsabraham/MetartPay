import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class SessionManagementScreen extends StatefulWidget {
  const SessionManagementScreen({super.key});

  @override
  State<SessionManagementScreen> createState() => _SessionManagementScreenState();
}

class _SessionManagementScreenState extends State<SessionManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      securityProvider.loadActiveSessions(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Consumer2<SecurityProvider, AuthProvider>(
        builder: (context, securityProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Please log in to view sessions'),
            );
          }

          if (securityProvider.sessionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = securityProvider.activeSessions;

          return RefreshIndicator(
            onRefresh: () async {
              await securityProvider.loadActiveSessions(authProvider.currentUser!.uid);
            },
            child: Column(
              children: [
                // Sessions Overview
                _buildSessionsOverview(sessions, securityProvider),
                
                // Sessions List
                Expanded(
                  child: sessions.isEmpty
                    ? const Center(
                        child: Text('No active sessions found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isCurrentSession = session.id == securityProvider.currentSession?.id;
                          
                          return _buildSessionCard(
                            context,
                            session,
                            isCurrentSession,
                            securityProvider,
                          );
                        },
                      ),
                ),
                
                // Action Buttons
                _buildActionButtons(context, securityProvider, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionsOverview(List<UserSession> sessions, SecurityProvider securityProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat(
                'Total Sessions',
                sessions.length.toString(),
                Colors.blue,
              ),
              _buildOverviewStat(
                'Current Device',
                '1',
                Colors.green,
              ),
              _buildOverviewStat(
                'Other Devices',
                (sessions.length - 1).toString(),
                Colors.orange,
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildSessionCard(
    BuildContext context,
    UserSession session,
    bool isCurrentSession,
    SecurityProvider securityProvider,
  ) {
    final riskLevel = securityProvider.getSessionRiskLevel(session);
    final riskColor = _getRiskColor(riskLevel);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentSession ? 4 : 2,
      color: isCurrentSession ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              // Device Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrentSession ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceIcon(session.operatingSystem),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Session Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          session.deviceName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentSession) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      session.deviceModel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          session.location,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Active for ${session.sessionDuration}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Risk Indicator
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor),
                    ),
                    child: Text(
                      riskLevel.toUpperCase(),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (!isCurrentSession)
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () => _showEndSessionDialog(context, session, securityProvider),
                      tooltip: 'End Session',
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Session Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSessionDetailRow('Login Time', _formatDateTime(session.loginTime)),
                const SizedBox(height: 4),
                _buildSessionDetailRow('Last Activity', _formatDateTime(session.lastActivity ?? session.loginTime)),
                const SizedBox(height: 4),
                _buildSessionDetailRow('IP Address', session.ipAddress),
                const SizedBox(height: 4),
                _buildSessionDetailRow('App Version', session.appVersion),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    SecurityProvider securityProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showEndAllSessionsDialog(context, securityProvider, authProvider),
              icon: const Icon(Icons.logout),
              label: const Text('End All Others'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _refreshSessions(context, securityProvider, authProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String operatingSystem) {
    if (operatingSystem.toLowerCase().contains('android')) {
      return Icons.android;
    } else if (operatingSystem.toLowerCase().contains('ios')) {
      return Icons.phone_iphone;
    } else if (operatingSystem.toLowerCase().contains('windows')) {
      return Icons.computer;
    } else if (operatingSystem.toLowerCase().contains('mac')) {
      return Icons.laptop_mac;
    } else {
      return Icons.devices;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showEndSessionDialog(
    BuildContext context,
    UserSession session,
    SecurityProvider securityProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Session'),
          content: Text(
            'Are you sure you want to end the session on ${session.deviceName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await securityProvider.endSession(session.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session ended successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Session'),
            ),
          ],
        );
      },
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
          title: const Text('End All Other Sessions'),
          content: const Text(
            'This will sign you out from all other devices. You will remain signed in on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await securityProvider.endAllOtherSessions(authProvider.currentUser!.uid);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All other sessions ended successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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

  void _refreshSessions(
    BuildContext context,
    SecurityProvider securityProvider,
    AuthProvider authProvider,
  ) async {
    await securityProvider.loadActiveSessions(authProvider.currentUser!.uid);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessions refreshed'),
        ),
      );
    }
  }
}