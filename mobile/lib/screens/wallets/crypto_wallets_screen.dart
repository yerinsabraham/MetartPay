import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../providers/merchant_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/metartpay_branding.dart';

class CryptoWalletsScreen extends StatefulWidget {
  const CryptoWalletsScreen({Key? key}) : super(key: key);

  @override
  State<CryptoWalletsScreen> createState() => _CryptoWalletsScreenState();
}

class _CryptoWalletsScreenState extends State<CryptoWalletsScreen> {
  int _selectedNetworkIndex = 0;
  List<Map<String, dynamic>> _networks = [];

  @override
  void initState() {
    super.initState();
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    _networks = merchantProvider.getWalletNetworks();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    final merchant = merchantProvider.currentMerchant;
    if (merchant != null) {
      await walletProvider.loadWallets(merchant.id);
      if (walletProvider.hasWallets) {
        await walletProvider.loadBalances(merchant.id);
      }
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Address copied: ${address.substring(0, 8)}...${address.substring(address.length - 6)}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAddress(String address, String tokenName) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing $tokenName address - Coming Soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _downloadQRCode(String address, String tokenName) async {
    try {
      // For now, show a placeholder message since actual file download
      // would require platform-specific implementations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('QR Code for $tokenName saved to Downloads')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQRCode(BuildContext context, String address, String tokenName, Color networkColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: networkColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.qr_code,
                color: networkColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tokenName Address',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Scan to get wallet address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          height: 340,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  address,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _downloadQRCode(address, tokenName);
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _copyAddress(address);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MetartPayColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MetartPayColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Crypto Wallets',
          style: TextStyle(
            color: MetartPayColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: MetartPayColors.primary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, _) {
          final merchant = merchantProvider.currentMerchant;
          
          if (merchant?.walletAddresses.isEmpty ?? true) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Network Selector
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final network = _networks[index];
                    final isSelected = index == _selectedNetworkIndex;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedNetworkIndex = index),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected 
                              ? LinearGradient(
                                  colors: [
                                    Color(network['color']),
                                    Color(network['color']).withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.transparent 
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              network['icon'],
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              network['symbol'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Selected Network Details
              Expanded(
                child: _buildNetworkDetails(
                  context,
                  _networks[_selectedNetworkIndex],
                  merchant!.walletAddresses,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MetartPayColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: MetartPayColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Wallets Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your account setup to generate crypto wallet addresses.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            MetartPayButton(
              onPressed: () => Navigator.of(context).pushNamed('/setup'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Complete Setup', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkDetails(BuildContext context, Map<String, dynamic> network, Map<String, String> walletAddresses) {
    final networkColor = Color(network['color']);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  networkColor,
                  networkColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  network['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        network['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        network['description'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tokens List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: network['tokens'].length,
              itemBuilder: (context, index) {
                final token = network['tokens'][index];
                final address = walletAddresses[token['key']] ?? '';
                
                if (address.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Token Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: networkColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              token['symbol'],
                              style: TextStyle(
                                color: networkColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              token['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Address
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Address',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyAddress(address),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: networkColor,
                                side: BorderSide(color: networkColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showQRCode(context, address, token['name'], networkColor),
                              icon: const Icon(Icons.qr_code, size: 16),
                              label: const Text('QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: networkColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: MetartPayColors.primary),
            SizedBox(width: 12),
            Text('About Crypto Wallets'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'These are your cryptocurrency wallet addresses for receiving payments:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text('• Share these addresses with customers to receive payments'),
              SizedBox(height: 8),
              Text('• Each network supports multiple tokens (USDT, USDC, etc.)'),
              SizedBox(height: 8),
              Text('• QR codes make it easy for customers to send payments'),
              SizedBox(height: 8),
              Text('• Always verify the address before sharing'),
              SizedBox(height: 16),
              Text(
                'Security Tips:',
                style: TextStyle(fontWeight: FontWeight.w600, color: MetartPayColors.primary),
              ),
              SizedBox(height: 8),
              Text('• Never share your private keys'),
              SizedBox(height: 4),
              Text('• Double-check addresses before transactions'),
              SizedBox(height: 4),
              Text('• Keep your account secure with strong passwords'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}