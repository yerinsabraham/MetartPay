import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import '../models/wallet_address.dart';

class WalletService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Get wallets for a merchant
  Future<List<Wallet>> getMerchantWallets(String merchantId, String idToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/wallets/merchant/$merchantId'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> walletsJson = data['data'];
          return walletsJson.map((json) => Wallet.fromJson(json)).toList();
        }
      } else if (response.statusCode == 404) {
        // No wallets found - this is normal for new merchants
        return [];
      }

      throw Exception('Failed to load wallets: ${response.statusCode}');
    } catch (e) {
      print('WalletService.getMerchantWallets error: $e');
      throw Exception('Failed to load wallets: $e');
    }
  }

  /// Generate wallets for a merchant (usually called after KYC approval)
  Future<List<Wallet>> generateWallets(String merchantId, String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/wallets/generate/$merchantId'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> walletsJson = data['data'];
          return walletsJson.map((json) => Wallet.fromJson(json)).toList();
        }
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Wallet generation failed');
      }

      throw Exception('Failed to generate wallets: ${response.statusCode}');
    } catch (e) {
      print('WalletService.generateWallets error: $e');
      throw Exception('Failed to generate wallets: $e');
    }
  }

  /// Get wallet balances for a merchant
  Future<List<WalletBalance>> getWalletBalances(String merchantId, String idToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/wallets/balances/$merchantId'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> balancesJson = data['data'];
          return balancesJson.map((json) => WalletBalance.fromJson(json)).toList();
        }
      } else if (response.statusCode == 404) {
        // No wallets found
        return [];
      }

      throw Exception('Failed to load wallet balances: ${response.statusCode}');
    } catch (e) {
      print('WalletService.getWalletBalances error: $e');
      throw Exception('Failed to load wallet balances: $e');
    }
  }

  /// Get supported blockchain networks
  List<BlockchainNetwork> getSupportedNetworks() {
    return [
      BlockchainNetwork(
        id: 'ETH',
        name: 'Ethereum',
        displayName: 'Ethereum',
        symbol: 'ETH',
        icon: '⟠',
        isTestnet: false,
      ),
      BlockchainNetwork(
        id: 'BSC',
        name: 'Binance Smart Chain',
        displayName: 'BSC',
        symbol: 'BNB',
        icon: '🌕',
        isTestnet: false,
      ),
      BlockchainNetwork(
        id: 'SOL',
        name: 'Solana',
        displayName: 'Solana',
        symbol: 'SOL',
        icon: '◎',
        isTestnet: false,
      ),
    ];
  }

  /// Get supported tokens
  List<CryptoToken> getSupportedTokens() {
    return [
      CryptoToken(
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        icon: '₮',
      ),
      CryptoToken(
        symbol: 'USDC',
        name: 'USD Coin',
        decimals: 6,
        icon: 'Ⓒ',
      ),
    ];
  }

  /// Get wallet addresses for a merchant (for payment link generation)
  Future<List<WalletAddress>> getWalletAddresses(String merchantId) async {
    try {
      // In a real implementation, this would call the backend API
      // For now, return demo addresses for supported networks
      return [
        WalletAddress(
          id: 'eth_${merchantId}_wallet',
          merchantId: merchantId,
          network: 'ETH',
          address: '0x742e4758d8dd346c15370b5c5d3eefc6b5ff0c2a',
          createdAt: DateTime.now(),
        ),
        WalletAddress(
          id: 'bsc_${merchantId}_wallet',
          merchantId: merchantId,
          network: 'BSC',
          address: '0x8ba1f109551bd432803012645hac136c975056c1',
          createdAt: DateTime.now(),
        ),
        WalletAddress(
          id: 'sol_${merchantId}_wallet',
          merchantId: merchantId,
          network: 'SOL',
          address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          createdAt: DateTime.now(),
        ),
        WalletAddress(
          id: 'matic_${merchantId}_wallet',
          merchantId: merchantId,
          network: 'MATIC',
          address: '0x742e4758d8dd346c15370b5c5d3eefc6b5ff0c2a',
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      print('WalletService.getWalletAddresses error: $e');
      throw Exception('Failed to load wallet addresses: $e');
    }
  }
}

/// Wallet model for the mobile app
class Wallet {
  final String id;
  final String merchantId;
  final String chain;
  final String publicAddress;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.merchantId,
    required this.chain,
    required this.publicAddress,
    this.metadata,
    required this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      merchantId: json['merchantId'],
      chain: json['chain'],
      publicAddress: json['publicAddress'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'chain': chain,
      'publicAddress': publicAddress,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get chainDisplayName {
    switch (chain) {
      case 'ETH':
        return 'Ethereum';
      case 'BSC':
        return 'BSC';
      case 'SOL':
        return 'Solana';
      default:
        return chain;
    }
  }

  String get chainIcon {
    switch (chain) {
      case 'ETH':
        return '⟠';
      case 'BSC':
        return '🌕';
      case 'SOL':
        return '◎';
      default:
        return '🔗';
    }
  }
}

/// Wallet balance model
class WalletBalance {
  final String chain;
  final String address;
  final double? nativeBalance;
  final Map<String, double>? tokens;
  final String? error;

  WalletBalance({
    required this.chain,
    required this.address,
    this.nativeBalance,
    this.tokens,
    this.error,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      chain: json['chain'],
      address: json['address'],
      nativeBalance: json['nativeBalance']?.toDouble(),
      tokens: json['tokens'] != null
          ? Map<String, double>.from(json['tokens'].map((key, value) => MapEntry(key, value.toDouble())))
          : null,
      error: json['error'],
    );
  }

  bool get hasError => error != null;
  
  double get usdtBalance => tokens?['USDT'] ?? 0.0;
  double get usdcBalance => tokens?['USDC'] ?? 0.0;
  double get totalStablecoinBalance => usdtBalance + usdcBalance;
}

/// Blockchain network model
class BlockchainNetwork {
  final String id;
  final String name;
  final String displayName;
  final String symbol;
  final String icon;
  final bool isTestnet;

  BlockchainNetwork({
    required this.id,
    required this.name,
    required this.displayName,
    required this.symbol,
    required this.icon,
    required this.isTestnet,
  });
}

/// Crypto token model
class CryptoToken {
  final String symbol;
  final String name;
  final int decimals;
  final String icon;

  CryptoToken({
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.icon,
  });
}