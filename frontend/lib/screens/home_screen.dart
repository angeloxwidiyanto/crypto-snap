import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../widgets/crypto_card.dart';
import '../widgets/crypto_chart.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/timeframe_selector.dart';
import '../widgets/coin_stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch trending coins when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CryptoService>().fetchTrendingCoins();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cryptoService = Provider.of<CryptoService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Snap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings page navigation
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Market'),
            Tab(text: 'Portfolio'),
          ],
          labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketTab(cryptoService),
          _buildPortfolioTab(),
        ],
      ),
    );
  }
  
  Widget _buildMarketTab(CryptoService cryptoService) {
    if (cryptoService.isLoading) {
      return const LoadingIndicator();
    }
    
    if (cryptoService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              cryptoService.error ?? 'Unknown error',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cryptoService.fetchTrendingCoins(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final selectedCoin = cryptoService.selectedCoin;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          if (selectedCoin != null) ...[
            // Chart section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedCoin.name} (${selectedCoin.symbol})',
                        style: AppTheme.headlineMedium,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${selectedCoin.currentPrice.toStringAsFixed(2)}',
                            style: AppTheme.headlineSmall,
                          ),
                          Row(
                            children: [
                              Icon(
                                selectedCoin.priceChangePercentage24h >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: selectedCoin.priceChangePercentage24h >= 0
                                    ? AppTheme.accentColor
                                    : AppTheme.errorColor,
                                size: 14,
                              ),
                              Text(
                                '${selectedCoin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: selectedCoin.priceChangePercentage24h >= 0
                                      ? AppTheme.accentColor
                                      : AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Timeframe selector
                  const TimeframeSelector(),
                  
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: CryptoChart(priceHistory: selectedCoin.priceHistory),
                  ),
                ],
              ),
            ),
            
            // Stats Card
            const CoinStatsCard(),
            
            const SizedBox(height: 16),
            
            // Title for coin list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Coins',
                    style: AppTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all coins page
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ],
          
          // Coin list section
          SizedBox(
            height: 350,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cryptoService.trendingCoins.length,
              itemBuilder: (context, index) {
                final coin = cryptoService.trendingCoins[index];
                return CryptoCard(
                  coin: coin,
                  isSelected: coin.id == selectedCoin?.id,
                  onTap: () => cryptoService.setSelectedCoin(coin),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPortfolioTab() {
    // Placeholder for portfolio tab
    return const Center(
      child: Text('Portfolio feature coming soon!'),
    );
  }
}
