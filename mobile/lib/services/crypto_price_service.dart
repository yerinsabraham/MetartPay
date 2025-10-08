import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoPriceService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  
  // Cache for storing prices to avoid excessive API calls
  final Map<String, CryptoPrice> _priceCache = {};
  DateTime? _lastCacheUpdate;
  
  // Cache duration in minutes
  static const int _cacheValidityMinutes = 2;

  // Supported cryptocurrencies with their CoinGecko IDs
  static const Map<String, String> _cryptoIds = {
    'USDT': 'tether',
    'USDC': 'usd-coin',
    'ETH': 'ethereum',
    'BNB': 'binancecoin',
    'BUSD': 'binance-usd',
    'MATIC': 'matic-network',
    'TRX': 'tron',
  };

  // Get real-time prices for multiple cryptocurrencies
  Future<Map<String, CryptoPrice>> getCryptoPrices({
    List<String>? cryptos,
    String baseCurrency = 'ngn',
  }) async {
    // Use provided crypto list or default to all supported cryptos
    final cryptoList = cryptos ?? _cryptoIds.keys.toList();
    
    // Check if cache is still valid
    if (_isCacheValid() && _hasCachedPrices(cryptoList)) {
      return _getCachedPrices(cryptoList);
    }

    try {
      // Build the API URL with crypto IDs
      final cryptoIds = cryptoList
          .map((crypto) => _cryptoIds[crypto])
          .where((id) => id != null)
          .join(',');

      final url = Uri.parse(
        '$_baseUrl/simple/price?ids=$cryptoIds&vs_currencies=$baseCurrency,usd&include_24hr_change=true&include_last_updated_at=true'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Parse the response and update cache
        final prices = <String, CryptoPrice>{};
        for (final crypto in cryptoList) {
          final cryptoId = _cryptoIds[crypto];
          if (cryptoId != null && data.containsKey(cryptoId)) {
            final priceData = data[cryptoId] as Map<String, dynamic>;
            prices[crypto] = CryptoPrice.fromJson(crypto, priceData, baseCurrency);
          }
        }
        
        // Update cache
        _updateCache(prices);
        
        return prices;
      } else {
        throw Exception('Failed to fetch crypto prices: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached prices if available, otherwise throw error
      if (_priceCache.isNotEmpty) {
        print('Using cached prices due to API error: $e');
        return _getCachedPrices(cryptoList);
      }
      throw Exception('Failed to fetch crypto prices: $e');
    }
  }

  // Get price for a single cryptocurrency
  Future<CryptoPrice?> getCryptoPrice(String crypto, {String baseCurrency = 'ngn'}) async {
    try {
      final prices = await getCryptoPrices(cryptos: [crypto], baseCurrency: baseCurrency);
      return prices[crypto];
    } catch (e) {
      print('Error fetching price for $crypto: $e');
      return null;
    }
  }

  // Convert Naira amount to crypto amount
  Future<double?> convertNairaToCrypto(double nairaAmount, String cryptoSymbol) async {
    try {
      final price = await getCryptoPrice(cryptoSymbol);
      if (price != null && price.priceInNGN > 0) {
        return nairaAmount / price.priceInNGN;
      }
      return null;
    } catch (e) {
      print('Error converting NGN to $cryptoSymbol: $e');
      return null;
    }
  }

  // Convert crypto amount to Naira
  Future<double?> convertCryptoToNaira(double cryptoAmount, String cryptoSymbol) async {
    try {
      final price = await getCryptoPrice(cryptoSymbol);
      if (price != null) {
        return cryptoAmount * price.priceInNGN;
      }
      return null;
    } catch (e) {
      print('Error converting $cryptoSymbol to NGN: $e');
      return null;
    }
  }

  // Get current USD to NGN rate (for fallback calculations)
  Future<double?> getUsdToNgnRate() async {
    try {
      final url = Uri.parse('$_baseUrl/simple/price?ids=usd-coin&vs_currencies=ngn');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['usd-coin']?['ngn'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error fetching USD to NGN rate: $e');
      return null;
    }
  }

  // Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastCacheUpdate!);
    return difference.inMinutes < _cacheValidityMinutes;
  }

  // Check if all required cryptos are in cache
  bool _hasCachedPrices(List<String> cryptos) {
    return cryptos.every((crypto) => _priceCache.containsKey(crypto));
  }

  // Get prices from cache
  Map<String, CryptoPrice> _getCachedPrices(List<String> cryptos) {
    final cachedPrices = <String, CryptoPrice>{};
    for (final crypto in cryptos) {
      if (_priceCache.containsKey(crypto)) {
        cachedPrices[crypto] = _priceCache[crypto]!;
      }
    }
    return cachedPrices;
  }

  // Update cache with new prices
  void _updateCache(Map<String, CryptoPrice> prices) {
    _priceCache.addAll(prices);
    _lastCacheUpdate = DateTime.now();
  }

  // Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _priceCache.clear();
    _lastCacheUpdate = null;
  }

  // Get supported cryptocurrencies
  static List<String> getSupportedCryptos() {
    return _cryptoIds.keys.toList();
  }

  // Check if a crypto is supported
  static bool isCryptoSupported(String crypto) {
    return _cryptoIds.containsKey(crypto.toUpperCase());
  }
}

class CryptoPrice {
  final String symbol;
  final double priceInNGN;
  final double priceInUSD;
  final double changePercentage24h;
  final DateTime lastUpdated;

  CryptoPrice({
    required this.symbol,
    required this.priceInNGN,
    required this.priceInUSD,
    required this.changePercentage24h,
    required this.lastUpdated,
  });

  factory CryptoPrice.fromJson(String symbol, Map<String, dynamic> json, String baseCurrency) {
    return CryptoPrice(
      symbol: symbol,
      priceInNGN: (json[baseCurrency] as num?)?.toDouble() ?? 0.0,
      priceInUSD: (json['usd'] as num?)?.toDouble() ?? 0.0,
      changePercentage24h: (json['${baseCurrency}_24h_change'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        ((json['last_updated_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'priceInNGN': priceInNGN,
      'priceInUSD': priceInUSD,
      'changePercentage24h': changePercentage24h,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPriceIncreasing => changePercentage24h > 0;
  bool get isPriceDecreasing => changePercentage24h < 0;
  
  String get formattedPriceNGN {
    if (priceInNGN >= 1000) {
      return '₦${priceInNGN.toStringAsFixed(0)}';
    } else if (priceInNGN >= 1) {
      return '₦${priceInNGN.toStringAsFixed(2)}';
    } else {
      return '₦${priceInNGN.toStringAsFixed(4)}';
    }
  }

  String get formattedPriceUSD {
    if (priceInUSD >= 1000) {
      return '\$${priceInUSD.toStringAsFixed(0)}';
    } else if (priceInUSD >= 1) {
      return '\$${priceInUSD.toStringAsFixed(2)}';
    } else {
      return '\$${priceInUSD.toStringAsFixed(4)}';
    }
  }

  String get formattedChangePercentage {
    final sign = changePercentage24h >= 0 ? '+' : '';
    return '$sign${changePercentage24h.toStringAsFixed(2)}%';
  }

  @override
  String toString() {
    return 'CryptoPrice(symbol: $symbol, priceNGN: $formattedPriceNGN, change: $formattedChangePercentage)';
  }
}