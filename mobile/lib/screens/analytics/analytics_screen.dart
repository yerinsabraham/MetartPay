import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/merchant_provider.dart';
import '../../models/models.dart';
import '../../widgets/metartpay_branding.dart';
import '../../services/firebase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';

  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _analyticsData;
  bool _isLoadingAnalytics = false;
  String? _analyticsError;

  final List<Map<String, dynamic>> _periods = [
    {'key': '1d', 'label': '24H'},
    {'key': '7d', 'label': '7D'},
    {'key': '30d', 'label': '30D'},
    {'key': '90d', 'label': '90D'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load merchant data and real analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final merchantProvider = context.read<MerchantProvider>();
      merchantProvider.loadMerchantInvoices();
      _loadRealAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAnalytics() async {
    final merchantProvider = context.read<MerchantProvider>();
    await merchantProvider.loadMerchantInvoices();
    await _loadRealAnalytics();
  }

  Future<void> _loadRealAnalytics() async {
    final merchantProvider = context.read<MerchantProvider>();
    final currentMerchant = merchantProvider.currentMerchant;

    if (currentMerchant == null) return;

    setState(() {
      _isLoadingAnalytics = true;
      _analyticsError = null;
    });

    try {
      final (startDate, endDate) = _getDateRangeForPeriod(_selectedPeriod);

      final analytics = await _firebaseService.getMerchantAnalytics(
        currentMerchant.id,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _analyticsData = analytics;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _analyticsError = 'Failed to load analytics: $e';
        _isLoadingAnalytics = false;
      });
    }
  }

  (DateTime, DateTime) _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case '1d':
        return (now.subtract(Duration(days: 1)), now);
      case '7d':
        return (now.subtract(Duration(days: 7)), now);
      case '30d':
        return (now.subtract(Duration(days: 30)), now);
      case '90d':
        return (now.subtract(Duration(days: 90)), now);
      default:
        return (now.subtract(Duration(days: 7)), now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Analytics & Reports',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
            Tab(icon: Icon(Icons.timeline), text: 'Trends'),
          ],
        ),
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, child) {
          // Show loading if either merchant data or analytics are loading
          if (merchantProvider.isLoading || _isLoadingAnalytics) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics data...'),
                ],
              ),
            );
          }

          // Show error if either has an error
          if (merchantProvider.error != null || _analyticsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _analyticsError ??
                        merchantProvider.error ??
                        'Unknown error',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.7 * 255).round(),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      merchantProvider.loadMerchantInvoices();
                      _loadRealAnalytics();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Use real analytics data if available, otherwise fallback to invoice-based analytics
          final AnalyticsData analytics;
          if (_analyticsData != null) {
            analytics = _createAnalyticsFromFirebaseData(_analyticsData!);
          } else {
            // Fallback to invoice-based analytics
            final invoices = merchantProvider.invoices;
            analytics = _calculateAnalytics(invoices);
          }

          return Column(
            children: [
              // Period selector
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Period: ', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _periods.map((period) {
                            final isSelected = _selectedPeriod == period['key'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(period['label']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPeriod = period['key'];
                                    });
                                    _loadRealAnalytics(); // Reload data for new period
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAnalytics,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(analytics, theme),
                      _buildBreakdownTab(analytics, theme),
                      _buildTrendsTab(analytics, theme),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshAnalytics,
        tooltip: 'Refresh Analytics',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsData analytics, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: [
              Text(
                'Period:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: _periods.map((period) {
                    final isSelected = _selectedPeriod == period['key'];
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period['key'];
                          });
                        }
                      },
                      label: Text(period['label']),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Revenue Overview Cards
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Revenue',
                  value:
                      '₦${NumberFormat('#,##0.00').format(analytics.totalRevenue)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  subtitle:
                      '+${analytics.revenueGrowth.toStringAsFixed(1)}% vs last period',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Total Payments',
                  value: '${analytics.totalPayments}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  subtitle:
                      '${analytics.successRate.toStringAsFixed(1)}% success rate',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Pending Amount',
                  value:
                      '₦${NumberFormat('#,##0.00').format(analytics.pendingAmount)}',
                  icon: Icons.schedule,
                  color: Colors.orange,
                  subtitle: '${analytics.pendingPayments} pending payments',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Avg. Transaction',
                  value:
                      '₦${NumberFormat('#,##0.00').format(analytics.averageTransaction)}',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  subtitle: 'Per successful payment',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...analytics.recentInvoices.isEmpty
                      ? [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_outlined,
                                    size: 48,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.4 * 255).round()),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recent activity',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha((0.7 * 255).round()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      : analytics.recentInvoices
                            .take(5)
                            .map((invoice) => _ActivityTile(invoice: invoice))
                            .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab(AnalyticsData analytics, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Status Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Status Distribution',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatusBreakdownChart(analytics: analytics),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cryptocurrency Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cryptocurrency Usage',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...analytics.cryptoBreakdown.entries.map((entry) {
                    return _CryptoBreakdownItem(
                      crypto: entry.key,
                      amount: entry.value['amount'],
                      count: entry.value['count'],
                      percentage:
                          (entry.value['count'] /
                          analytics.totalPayments *
                          100),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Blockchain Network Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blockchain Networks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...analytics.chainBreakdown.entries.map((entry) {
                    return _ChainBreakdownItem(
                      chain: entry.key,
                      count: entry.value,
                      percentage: (entry.value / analytics.totalPayments * 100),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(AnalyticsData analytics, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trends',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: const Center(
                      child: Text(
                        'Revenue Chart\n(Chart library integration needed)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Volume Trends',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: const Center(
                      child: Text(
                        'Volume Chart\n(Chart library integration needed)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AnalyticsData _calculateAnalytics(List<Invoice> invoices) {
    final now = DateTime.now();
    final filteredInvoices = _filterInvoicesByPeriod(invoices, _selectedPeriod);

    final paidInvoices = filteredInvoices
        .where((i) => i.status == 'paid')
        .toList();
    final pendingInvoices = filteredInvoices
        .where((i) => i.status == 'pending')
        .toList();

    final totalRevenue = paidInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.amountNaira,
    );
    final pendingAmount = pendingInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.amountNaira,
    );
    final averageTransaction = paidInvoices.isNotEmpty
        ? totalRevenue / paidInvoices.length
        : 0.0;
    final successRate = invoices.isNotEmpty
        ? (paidInvoices.length / invoices.length * 100)
        : 0.0;

    // Calculate crypto breakdown
    final cryptoBreakdown = <String, Map<String, dynamic>>{};
    for (final invoice in paidInvoices) {
      final crypto = invoice.cryptoSymbol;
      if (!cryptoBreakdown.containsKey(crypto)) {
        cryptoBreakdown[crypto] = {'amount': 0.0, 'count': 0};
      }
      cryptoBreakdown[crypto]!['amount'] += invoice.amountNaira;
      cryptoBreakdown[crypto]!['count']++;
    }

    // Calculate chain breakdown
    final chainBreakdown = <String, int>{};
    for (final invoice in paidInvoices) {
      final chain = invoice.chain;
      chainBreakdown[chain] = (chainBreakdown[chain] ?? 0) + 1;
    }

    return AnalyticsData(
      totalRevenue: totalRevenue,
      totalPayments: filteredInvoices.length,
      pendingAmount: pendingAmount,
      pendingPayments: pendingInvoices.length,
      averageTransaction: averageTransaction,
      successRate: successRate,
      revenueGrowth: 12.5, // Mock growth percentage
      cryptoBreakdown: cryptoBreakdown,
      chainBreakdown: chainBreakdown,
      recentInvoices: invoices.take(10).toList(),
    );
  }

  List<Invoice> _filterInvoicesByPeriod(List<Invoice> invoices, String period) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (period) {
      case '1d':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case '7d':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '90d':
        cutoff = now.subtract(const Duration(days: 90));
        break;
      default:
        cutoff = now.subtract(const Duration(days: 7));
    }

    return invoices
        .where((invoice) => invoice.createdAt.isAfter(cutoff))
        .toList();
  }
}

AnalyticsData _createAnalyticsFromFirebaseData(Map<String, dynamic> data) {
  // Extract recent transactions and convert to Invoice format for compatibility
  final recentTransactions =
      (data['recentTransactions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  final recentInvoices = <Invoice>[];

  // Create crypto and chain breakdown from Firebase data
  final cryptoBreakdown = <String, Map<String, dynamic>>{};
  final chainBreakdown = <String, int>{};

  // Process recent transactions to build breakdowns
  for (final txData in recentTransactions) {
    final cryptoSymbol = txData['cryptoSymbol'] ?? txData['token'] ?? 'Unknown';
    final chain = txData['chain'] ?? 'ethereum';
    final amountNaira = (txData['amountNaira'] as num?)?.toDouble() ?? 0.0;

    // Build crypto breakdown
    if (!cryptoBreakdown.containsKey(cryptoSymbol)) {
      cryptoBreakdown[cryptoSymbol] = {'amount': 0.0, 'count': 0};
    }
    cryptoBreakdown[cryptoSymbol]!['amount'] =
        (cryptoBreakdown[cryptoSymbol]!['amount'] as double) + amountNaira;
    cryptoBreakdown[cryptoSymbol]!['count'] =
        (cryptoBreakdown[cryptoSymbol]!['count'] as int) + 1;

    // Build chain breakdown
    chainBreakdown[chain] = (chainBreakdown[chain] ?? 0) + 1;

    // Create compatible invoice for UI (if we need recent invoices display)
    try {
      final invoice = Invoice(
        id: txData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        merchantId: txData['merchantId'] ?? '',
        reference: txData['reference'] ?? 'TXN-${txData['id'] ?? ''}',
        amountNaira: amountNaira,
        amountCrypto: (txData['amountCrypto'] as num?)?.toDouble() ?? 0.0,
        cryptoSymbol: cryptoSymbol,
        chain: chain,
        receivingAddress: txData['receivingAddress'] ?? '',
        status: txData['status'] ?? 'completed',
        createdAt:
            DateTime.tryParse(txData['createdAt'] ?? '') ?? DateTime.now(),
        feeNaira: (txData['feeNaira'] as num?)?.toDouble() ?? 0.0,
        fxRate: (txData['fxRate'] as num?)?.toDouble() ?? 1.0,
      );
      recentInvoices.add(invoice);
    } catch (e) {
      // Skip invalid transaction data
      debugPrint('Error creating invoice from transaction: $e');
    }
  }

  return AnalyticsData(
    totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    totalPayments: (data['totalTransactions'] as num?)?.toInt() ?? 0,
    pendingAmount: 0.0, // Firebase analytics focuses on completed transactions
    pendingPayments: 0, // We can add pending analytics later if needed
    averageTransaction:
        (data['averageTransactionValue'] as num?)?.toDouble() ?? 0.0,
    successRate: (data['successRate'] as num?)?.toDouble() ?? 0.0,
    revenueGrowth: 0.0, // We can calculate this by comparing periods later
    cryptoBreakdown: cryptoBreakdown,
    chainBreakdown: chainBreakdown,
    recentInvoices: recentInvoices,
  );
}

class AnalyticsData {
  final double totalRevenue;
  final int totalPayments;
  final double pendingAmount;
  final int pendingPayments;
  final double averageTransaction;
  final double successRate;
  final double revenueGrowth;
  final Map<String, Map<String, dynamic>> cryptoBreakdown;
  final Map<String, int> chainBreakdown;
  final List<Invoice> recentInvoices;

  AnalyticsData({
    required this.totalRevenue,
    required this.totalPayments,
    required this.pendingAmount,
    required this.pendingPayments,
    required this.averageTransaction,
    required this.successRate,
    required this.revenueGrowth,
    required this.cryptoBreakdown,
    required this.chainBreakdown,
    required this.recentInvoices,
  });
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Invoice invoice;

  const _ActivityTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = invoice.metadata?['description'] ?? 'Payment Link';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getStatusColor(
              invoice.status,
            ).withAlpha((0.1 * 255).round()),
            child: Icon(
              _getStatusIcon(invoice.status),
              size: 16,
              color: _getStatusColor(invoice.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₦${NumberFormat('#,##0.00').format(invoice.amountNaira)} • ${invoice.cryptoSymbol}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.7 * 255).round(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd').format(invoice.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class _StatusBreakdownChart extends StatelessWidget {
  final AnalyticsData analytics;

  const _StatusBreakdownChart({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _StatusItem(
          label: 'Successful',
          count: analytics.totalPayments - analytics.pendingPayments,
          total: analytics.totalPayments,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _StatusItem(
          label: 'Pending',
          count: analytics.pendingPayments,
          total: analytics.totalPayments,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            '$count (${(percentage * 100).toStringAsFixed(1)}%)',
            style: TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _CryptoBreakdownItem extends StatelessWidget {
  final String crypto;
  final double amount;
  final int count;
  final double percentage;

  const _CryptoBreakdownItem({
    required this.crypto,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              crypto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₦${NumberFormat('#,##0').format(amount)}'),
                Text(
                  '$count transactions',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ChainBreakdownItem extends StatelessWidget {
  final String chain;
  final int count;
  final double percentage;

  const _ChainBreakdownItem({
    required this.chain,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              _getChainDisplayName(chain),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text('$count transactions')),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getChainDisplayName(String chain) {
    switch (chain.toLowerCase()) {
      case 'ethereum':
        return 'Ethereum';
      case 'bsc':
        return 'BSC';
      case 'polygon':
        return 'Polygon';
      case 'tron':
        return 'Tron';
      default:
        return chain;
    }
  }
}
