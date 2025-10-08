import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class SecurityLogsScreen extends StatefulWidget {
  const SecurityLogsScreen({super.key});

  @override
  State<SecurityLogsScreen> createState() => _SecurityLogsScreenState();
}

class _SecurityLogsScreenState extends State<SecurityLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSeverity;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSecurityLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSecurityLogs() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      securityProvider.loadSecurityLogs(
        authProvider.currentUser!.uid,
        severity: _selectedSeverity,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Logs'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSecurityLogs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Critical'),
            Tab(text: 'High'),
            Tab(text: 'Medium'),
            Tab(text: 'Low'),
          ],
        ),
      ),
      body: Consumer2<SecurityProvider, AuthProvider>(
        builder: (context, securityProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Please log in to view security logs'),
            );
          }

          if (securityProvider.logsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Statistics Overview
              _buildStatisticsOverview(securityProvider),
              
              // Logs Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogsList(securityProvider.securityLogs),
                    _buildLogsList(securityProvider.getLogsBySeverity('critical')),
                    _buildLogsList(securityProvider.getLogsBySeverity('high')),
                    _buildLogsList(securityProvider.getLogsBySeverity('medium')),
                    _buildLogsList(securityProvider.getLogsBySeverity('low')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsOverview(SecurityProvider securityProvider) {
    final stats = securityProvider.getLogStatistics();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Security Activity Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total']!, Colors.blue),
              _buildStatItem('Critical', stats['critical']!, Colors.red),
              _buildStatItem('High', stats['high']!, Colors.orange),
              _buildStatItem('Medium', stats['medium']!, Colors.yellow[700]!),
              _buildStatItem('Low', stats['low']!, Colors.green),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
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

  Widget _buildLogsList(List<SecurityLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No security logs found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadSecurityLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogCard(log);
        },
      ),
    );
  }

  Widget _buildLogCard(SecurityLog log) {
    final severityColor = _getSeverityColor(log.severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                // Severity Indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Event Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEventIcon(log.eventType),
                    color: severityColor,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Log Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.eventDescription,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: severityColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              log.severity.toUpperCase(),
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            log.formattedTimestamp,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.devices, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              log.deviceId.length > 8 ? '${log.deviceId.substring(0, 8)}...' : log.deviceId,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            log.location ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.public, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            log.ipAddress,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'failed_login':
        return Icons.error;
      case 'session_management':
        return Icons.devices;
      case 'biometric_auth':
        return Icons.fingerprint;
      case 'transaction':
        return Icons.payment;
      case 'security_settings':
        return Icons.security;
      case 'password_change':
        return Icons.lock_reset;
      default:
        return Icons.info;
    }
  }

  void _showLogDetails(SecurityLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getEventIcon(log.eventType),
                      color: _getSeverityColor(log.severity),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Security Log Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailItem('Event Type', log.eventType),
                    _buildDetailItem('Description', log.eventDescription),
                    _buildDetailItem('Severity', log.severity.toUpperCase()),
                    _buildDetailItem('Timestamp', log.formattedTimestamp),
                    _buildDetailItem('Device ID', log.deviceId),
                    _buildDetailItem('IP Address', log.ipAddress),
                    _buildDetailItem('Location', log.location ?? 'Unknown'),
                    _buildDetailItem('Session ID', log.sessionId),
                    
                    if (log.eventData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Additional Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.eventData.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Security Logs'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Severity Filter
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Severity'),
                    value: _selectedSeverity,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Severities')),
                      const DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      const DropdownMenuItem(value: 'high', child: Text('High')),
                      const DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      const DropdownMenuItem(value: 'low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeverity = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(_startDate?.toString().split(' ')[0] ?? 'Start Date'),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(_endDate?.toString().split(' ')[0] ?? 'End Date'),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSeverity = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {});
                    _loadSecurityLogs();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}