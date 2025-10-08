import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/payment_link_provider.dart';
import '../../providers/merchant_provider.dart';
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
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Links'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePaymentLinkScreen(),
                ),
              );
              
              if (result == true) {
                // Refresh the list
                final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
                await paymentLinkProvider.loadPaymentLinks();
              }
            },
          ),
        ],
      ),
      body: Consumer<PaymentLinkProvider>(
        builder: (context, paymentLinkProvider, child) {
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
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading payment links',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentLinkProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await paymentLinkProvider.loadPaymentLinks();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPaymentLinksList(paymentLinkProvider.activePaymentLinks, 'active'),
              _buildPaymentLinksList(paymentLinkProvider.inactivePaymentLinks, 'inactive'),
              _buildPaymentLinksList(paymentLinkProvider.paymentLinks, 'all'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePaymentLinkScreen(),
            ),
          );
          
          if (result == true) {
            final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
            await paymentLinkProvider.loadPaymentLinks();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
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
                  : 'No ${filter} payment links',
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePaymentLinkScreen(),
                  ),
                );
                
                if (result == true) {
                  final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
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
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalPayments payments received',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        '${option['network']} ${option['token']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[800],
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
                        color: Colors.grey[600],
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

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Active';
        break;
      case 'inactive':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'Inactive';
        break;
      case 'expired':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Expired';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _sharePaymentLink(Map<String, dynamic> paymentLink) {
    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
    final url = paymentLinkProvider.getPaymentUrl(paymentLink['id']);
    
    Share.share(
      'Pay ${paymentLink['title']} - ₦${paymentLink['amount']}\n\n$url',
      subject: 'Payment Request - ${paymentLink['title']}',
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
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  
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
                    final paymentLinkProvider = Provider.of<PaymentLinkProvider>(context, listen: false);
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