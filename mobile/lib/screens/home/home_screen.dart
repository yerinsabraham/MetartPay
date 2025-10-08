import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetartPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, _) {
          if (merchantProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (merchantProvider.merchants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No merchants found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a merchant account to start accepting payments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Merchant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          merchantProvider.currentMerchant?.businessName ?? 'No merchant selected',
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (merchantProvider.currentMerchant != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'KYC Status: ${merchantProvider.currentMerchant!.kycStatus.toUpperCase()}',
                            style: TextStyle(
                              color: merchantProvider.currentMerchant!.kycStatus == 'verified'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 32,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₦${merchantProvider.totalRevenue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Total Revenue'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.pending_actions,
                                size: 32,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₦${merchantProvider.totalPendingAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Pending'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickActionButton(
                          icon: Icons.add,
                          color: Colors.green,
                          label: 'Create',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Create Invoice screen - Coming soon')),
                            );
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.list,
                          color: Colors.blue,
                          label: 'View',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoices screen - Coming soon')),
                            );
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.qr_code_scanner,
                          color: Colors.purple,
                          label: 'Payment',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('QR Scanner - Coming soon')),
                            );
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.call_received,
                          color: Colors.teal,
                          label: 'Receive',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receive Payment - Coming soon')),
                            );
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.receipt_long,
                          color: Colors.orange,
                          label: 'Transaction',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transactions - Coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

                const SizedBox(height: 24),

                // Recent Invoices
                if (merchantProvider.invoices.isNotEmpty) ...[
                  const Text(
                    'Recent Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...merchantProvider.invoices.take(5).map((invoice) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: invoice.isPaid ? Colors.green : Colors.orange,
                        child: Icon(
                          invoice.isPaid ? Icons.check : Icons.access_time,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('₦${invoice.amountNaira.toStringAsFixed(2)}'),
                      subtitle: Text(
                        '${invoice.amountCrypto.toStringAsFixed(6)} ${invoice.cryptoSymbol} • ${invoice.chainDisplayName}',
                      ),
                      trailing: Text(
                        invoice.statusDisplayName,
                        style: TextStyle(
                          color: invoice.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        // TODO: Navigate to invoice details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invoice ${invoice.reference}'),
                          ),
                        );
                      },
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}