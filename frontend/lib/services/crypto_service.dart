import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class CryptoService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:8080/api';
  
  List<CryptoModel> _trendingCoins = [];
  CryptoModel? _selectedCoin;
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '1d'; // Default timeframe
  Map<String, dynamic>? _selectedCoinStats;
  
  // Getters
  List<CryptoModel> get trendingCoins => _trendingCoins;
  CryptoModel? get selectedCoin => _selectedCoin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimeframe => _selectedTimeframe;
  Map<String, dynamic>? get selectedCoinStats => _selectedCoinStats;

  // Available timeframes
  List<String> get timeframes => ['1h', '1d', '7d', '30d', '90d', '1y'];

  // Set selected coin
  void setSelectedCoin(CryptoModel coin) {
    _selectedCoin = coin;
    _fetchCoinStats(coin.id);
    fetchCoinPriceHistory(coin.id, _selectedTimeframe);
    notifyListeners();
  }
  
  // Set selected timeframe
  void setTimeframe(String timeframe) {
    if (_selectedTimeframe != timeframe) {
      _selectedTimeframe = timeframe;
      if (_selectedCoin != null) {
        fetchCoinPriceHistory(_selectedCoin!.id, timeframe);
      }
      notifyListeners();
    }
  }

  // Fetch trending coins from backend
  Future<void> fetchTrendingCoins() async {
    _setLoading(true);
    
    try {
      // Call the backend for list of coins
      final response = await http.get(
        Uri.parse('$_baseUrl/coins'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coinsList = List<Map<String, dynamic>>.from(data['coins'] ?? []);
        
        List<CryptoModel> coins = [];
        for (final coinData in coinsList) {
          final coin = await fetchCoinData(coinData['id']);
          coins.add(coin);
        }
        
        _trendingCoins = coins;
        if (_trendingCoins.isNotEmpty && _selectedCoin == null) {
          _selectedCoin = _trendingCoins.first;
          _fetchCoinStats(_selectedCoin!.id);
        }
        
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Failed to load coins (${response.statusCode})');
      }
    } catch (e) {
      _setError('Failed to fetch trending coins: $e');
    }
  }

  // Fetch specific coin data
  Future<CryptoModel> fetchCoinData(String symbol) async {
    try {
      // Get prices from backend
      final response = await http.get(
        Uri.parse('$_baseUrl/prices/$symbol'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final priceHistory = List<double>.from(data['prices'] ?? []);
        
        // Since our backend provides limited data, we'll create a simplified model
        return CryptoModel(
          id: symbol,
          symbol: _getCoinSymbol(symbol),
          name: _getCoinName(symbol),
          image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png', // Placeholder
          currentPrice: priceHistory.isNotEmpty ? priceHistory.last : 0.0,
          priceChangePercentage24h: _calculatePriceChangePercentage(priceHistory),
          marketCap: 0.0, // Will be updated when stats are fetched
          marketCapRank: 0, // Not available from our basic backend
          totalVolume: 0.0, // Will be updated when stats are fetched
          high24h: priceHistory.isNotEmpty ? priceHistory.reduce((a, b) => a > b ? a : b) : 0.0,
          low24h: priceHistory.isNotEmpty ? priceHistory.reduce((a, b) => a < b ? a : b) : 0.0,
          priceHistory: priceHistory,
        );
      } else {
        throw Exception('Failed to load coin data (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching coin data: $e');
    }
  }
  
  // Fetch coin price history with specified timeframe
  Future<void> fetchCoinPriceHistory(String symbol, String timeframe) async {
    if (_selectedCoin == null || _selectedCoin!.id != symbol) return;
    
    _setLoading(true);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/prices/$symbol/$timeframe'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final priceHistory = List<double>.from(data['prices'] ?? []);
        
        // Update the selected coin with new price history
        _selectedCoin = CryptoModel(
          id: _selectedCoin!.id,
          name: _selectedCoin!.name,
          symbol: _selectedCoin!.symbol,
          image: _selectedCoin!.image,
          currentPrice: priceHistory.isNotEmpty ? priceHistory.last : _selectedCoin!.currentPrice,
          priceChangePercentage24h: _calculatePriceChangePercentage(priceHistory),
          marketCap: _selectedCoin!.marketCap,
          marketCapRank: _selectedCoin!.marketCapRank,
          totalVolume: _selectedCoin!.totalVolume,
          high24h: priceHistory.isNotEmpty ? priceHistory.reduce((a, b) => a > b ? a : b) : _selectedCoin!.high24h,
          low24h: priceHistory.isNotEmpty ? priceHistory.reduce((a, b) => a < b ? a : b) : _selectedCoin!.low24h,
          priceHistory: priceHistory,
        );
        
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Failed to load coin history (${response.statusCode})');
      }
    } catch (e) {
      _setError('Error fetching coin history: $e');
    }
  }
  
  // Fetch detailed statistics for a coin
  Future<void> _fetchCoinStats(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/$symbol'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _selectedCoinStats = data['stats'];
        
        // If we have a selected coin and stats, update the coin with additional data
        if (_selectedCoin != null && _selectedCoinStats != null) {
          _selectedCoin = CryptoModel(
            id: _selectedCoin!.id,
            name: _selectedCoin!.name,
            symbol: _selectedCoin!.symbol,
            image: _selectedCoin!.image,
            currentPrice: _selectedCoin!.currentPrice,
            priceChangePercentage24h: _selectedCoin!.priceChangePercentage24h,
            marketCap: _selectedCoinStats!['market_cap'] ?? 0.0,
            marketCapRank: 0, // Not provided by our backend
            totalVolume: _selectedCoinStats!['volume_24h'] ?? 0.0,
            high24h: _selectedCoin!.high24h,
            low24h: _selectedCoin!.low24h,
            priceHistory: _selectedCoin!.priceHistory,
          );
          notifyListeners();
        }
      } else {
        print('Failed to load coin stats (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching coin stats: $e');
      // We don't set error here as this is a supplementary data fetch
    }
  }

  // Helper method to set error state
  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }
  
  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }
  
  // Calculate price change percentage
  double _calculatePriceChangePercentage(List<double> prices) {
    if (prices.length < 2) return 0.0;
    final firstPrice = prices.first;
    final lastPrice = prices.last;
    
    if (firstPrice == 0) return 0.0;
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }
  
  // Get coin name from symbol 
  String _getCoinName(String symbol) {
    final names = {
      'bitcoin': 'Bitcoin',
      'ethereum': 'Ethereum',
      'ripple': 'XRP',
      'cardano': 'Cardano',
      'solana': 'Solana',
      'dogecoin': 'Dogecoin',
      'polkadot': 'Polkadot',
    };
    
    return names[symbol.toLowerCase()] ?? symbol.toUpperCase();
  }
  
  // Get coin symbol from id
  String _getCoinSymbol(String id) {
    final symbols = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'ripple': 'XRP',
      'cardano': 'ADA',
      'solana': 'SOL',
      'dogecoin': 'DOGE',
      'polkadot': 'DOT',
    };
    
    return symbols[id.toLowerCase()] ?? id.toUpperCase();
  }
}
