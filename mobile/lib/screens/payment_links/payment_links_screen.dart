import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/payment_link_provider.dart';
// removed unused merchant_provider import
import 'create_payment_link_screen.dart';
import 'payment_link_details_screen.dart';

class PaymentLinksScreen extends StatefulWidget {
  const PaymentLinksScreen({super.key});

  @override
  State<PaymentLinksScreen> createState() => _PaymentLinksScreenState();
}

class _PaymentLinksScreenState extends State<PaymentLinksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
      await paymentLinkProvider.loadPaymentLinks();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Payment Links'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: cs.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.7),
          indicatorColor: cs.onPrimary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePaymentLinkScreen(),
                ),
              );
              
              if (result == true) {
                if (!mounted) return;
                await paymentLinkProvider.loadPaymentLinks();
              }
            },
          ),
        ],
      ),
      body: Consumer<PaymentLinkProvider>(
        builder: (context, paymentLinkProvider, child) {
          // show a small banner when we're showing cached data after failures
          final showCachedBanner = paymentLinkProvider.usedCache == true;
          if (paymentLinkProvider.isLoading && !_isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (paymentLinkProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: cs.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading payment links',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentLinkProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      paymentLinkProvider.clearError();
                      await paymentLinkProvider.loadPaymentLinks();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (showCachedBanner)
                Material(
                  color: cs.surfaceContainerHighest,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Showing cached payment links (server unavailable). Pull to retry.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            paymentLinkProvider.clearError();
                            await paymentLinkProvider.loadPaymentLinks();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
            controller: _tabController,
            children: [
              _buildPaymentLinksList(paymentLinkProvider.activePaymentLinks, 'active'),
              _buildPaymentLinksList(paymentLinkProvider.inactivePaymentLinks, 'inactive'),
              _buildPaymentLinksList(paymentLinkProvider.paymentLinks, 'all'),
            ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.secondary,
              onPressed: () async {
                final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePaymentLinkScreen(),
                  ),
                );
                
                if (result == true) {
                  if (!mounted) return;
                  await paymentLinkProvider.loadPaymentLinks();
                }
              },
        child: Icon(Icons.add, color: cs.onSecondary),
      ),
    );
  }

  Widget _buildPaymentLinksList(List<Map<String, dynamic>> paymentLinks, String filter) {
    if (paymentLinks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
        filter == 'all' 
          ? 'No payment links yet'
          : 'No $filter payment links',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first payment link to start accepting crypto payments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePaymentLinkScreen(),
                  ),
                );
          
                if (result == true) {
                  if (!mounted) return;
                  await paymentLinkProvider.loadPaymentLinks();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Payment Link'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
        await paymentLinkProvider.loadPaymentLinks();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paymentLinks.length,
        itemBuilder: (context, index) {
          final paymentLink = paymentLinks[index];
          return _buildPaymentLinkCard(paymentLink);
        },
      ),
    );
  }

  Widget _buildPaymentLinkCard(Map<String, dynamic> paymentLink) {
    final amount = paymentLink['amount']?.toDouble() ?? 0.0;
    final totalPayments = paymentLink['totalPayments'] ?? 0;
    final status = paymentLink['status'] ?? 'unknown';
    final cryptoOptions = List.from(paymentLink['cryptoOptions'] ?? []);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentLinkDetailsScreen(paymentLink: paymentLink),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paymentLink['title'] ?? 'Untitled Link',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (paymentLink['description'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              paymentLink['description'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Show status chip and an additional small "Cached"/"Stale" pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(status, context),
                      const SizedBox(height: 6),
                      Builder(builder: (ctx) {
                        final provider = Provider.of<PaymentLinkProvider>(ctx, listen: false);
                        if (provider.usedCache == true) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Cached',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₦${amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalPayments payments received',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.share,
                        onTap: () => _sharePaymentLink(paymentLink),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: status == 'active' ? Icons.pause : Icons.play_arrow,
                        onTap: () => _togglePaymentLinkStatus(paymentLink),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.more_vert,
                        onTap: () => _showPaymentLinkOptions(paymentLink),
                      ),
                    ],
                  ),
                ],
              ),
              if (cryptoOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: cryptoOptions.take(3).map((option) {
                    final cs = Theme.of(context).colorScheme;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        '${option['network']} ${option['token']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (cryptoOptions.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${cryptoOptions.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
  backgroundColor = cs.primary.withValues(alpha: 0.12);
        textColor = cs.primary;
        label = 'Active';
        break;
      case 'inactive':
  backgroundColor = cs.secondary.withValues(alpha: 0.12);
        textColor = cs.secondary;
        label = 'Inactive';
        break;
      case 'expired':
  backgroundColor = cs.error.withValues(alpha: 0.12);
        textColor = cs.error;
        label = 'Expired';
        break;
      default:
  backgroundColor = cs.surface.withValues(alpha: 0.06);
        textColor = cs.onSurface;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Icon(
          icon,
          size: 18,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  void _sharePaymentLink(Map<String, dynamic> paymentLink) {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
    final url = paymentLinkProvider.getPaymentUrl(paymentLink['id']);

    SharePlus.instance.share(
      ShareParams(
        text: 'Pay ${paymentLink['title']} - ₦${paymentLink['amount']}\n\n$url',
        subject: 'Payment Request - ${paymentLink['title']}',
      ),
    );
  }

  Future<void> _togglePaymentLinkStatus(Map<String, dynamic> paymentLink) async {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
    await paymentLinkProvider.togglePaymentLinkStatus(
      paymentLink['id'], 
      paymentLink['status'],
    );
  }

  void _showPaymentLinkOptions(Map<String, dynamic> paymentLink) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentLinkDetailsScreen(paymentLink: paymentLink),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
                  final url = paymentLinkProvider.getPaymentUrl(paymentLink['id']);
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment link copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePaymentLink(paymentLink);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: cs.error),
                title: Text('Delete', style: TextStyle(color: cs.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Payment Link'),
                      content: const Text('Are you sure you want to delete this payment link? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    if (!mounted) return;
                    await paymentLinkProvider.deletePaymentLink(paymentLink['id']);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}