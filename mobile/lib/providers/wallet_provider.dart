import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wallet_service.dart';
import '../services/firebase_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  final FirebaseService _firebaseService = FirebaseService();

  List<Wallet> _wallets = [];
  List<WalletBalance> _balances = [];
  bool _isLoading = false;
  String? _error;

  List<Wallet> get wallets => _wallets;
  List<WalletBalance> get balances => _balances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasWallets => _wallets.isNotEmpty;
  bool get walletsGenerated => _wallets.isNotEmpty;

  /// Get wallet for a specific chain
  Wallet? getWalletForChain(String chain) {
    try {
      return _wallets.firstWhere((wallet) => wallet.chain == chain);
    } catch (e) {
      return null;
    }
  }

  /// Get balance for a specific chain
  WalletBalance? getBalanceForChain(String chain) {
    try {
      return _balances.firstWhere((balance) => balance.chain == chain);
    } catch (e) {
      return null;
    }
  }

  /// Load wallets for current merchant
  Future<void> loadWallets(String merchantId) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get authentication token');
      _wallets = await _walletService.getMerchantWallets(merchantId, idToken);
      
      print('DEBUG: Loaded ${_wallets.length} wallets for merchant $merchantId');
      notifyListeners();
      
    } catch (e) {
      _setError('Failed to load wallets: $e');
      print('DEBUG: Error loading wallets: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Generate wallets for merchant (after KYC approval)
  Future<bool> generateWallets(String merchantId) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get authentication token');
      _wallets = await _walletService.generateWallets(merchantId, idToken);
      
      print('DEBUG: Generated ${_wallets.length} wallets for merchant $merchantId');
      notifyListeners();
      return true;
      
    } catch (e) {
      _setError('Failed to generate wallets: $e');
      print('DEBUG: Error generating wallets: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load wallet balances
  Future<void> loadBalances(String merchantId) async {
    try {
      _setLoading(true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get authentication token');
      _balances = await _walletService.getWalletBalances(merchantId, idToken);
      
      print('DEBUG: Loaded balances for ${_balances.length} wallets');
      notifyListeners();
      
    } catch (e) {
      print('DEBUG: Error loading balances: $e');
      // Don't set error for balance loading failures - it's not critical
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh both wallets and balances
  Future<void> refresh(String merchantId) async {
    await loadWallets(merchantId);
    if (_wallets.isNotEmpty) {
      await loadBalances(merchantId);
    }
  }

  /// Get total balance across all wallets in Naira
  Future<double> getTotalBalanceInNaira() async {
    double total = 0.0;
    
    for (final balance in _balances) {
      if (!balance.hasError) {
        // Convert USDT/USDC to Naira (you'll need to get current exchange rates)
        total += balance.totalStablecoinBalance * 1650; // Example rate: 1 USD = 1650 NGN
      }
    }
    
    return total;
  }

  /// Get supported networks
  List<BlockchainNetwork> getSupportedNetworks() {
    return _walletService.getSupportedNetworks();
  }

  /// Get supported tokens
  List<CryptoToken> getSupportedTokens() {
    return _walletService.getSupportedTokens();
  }

  /// Clear wallet data (on logout)
  void clear() {
    _wallets = [];
    _balances = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Copy wallet address to clipboard and show feedback
  Future<void> copyAddressToClipboard(String address) async {
    try {
      // You can add clipboard functionality here
      print('DEBUG: Copied address to clipboard: $address');
    } catch (e) {
      print('DEBUG: Failed to copy address: $e');
    }
  }
}