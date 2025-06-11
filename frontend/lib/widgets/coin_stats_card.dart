import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crypto_service.dart';
import '../utils/number_formatter.dart';

class CoinStatsCard extends StatelessWidget {
  const CoinStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoService>(
      builder: (context, cryptoService, _) {
        final selectedCoin = cryptoService.selectedCoin;
        final coinStats = cryptoService.selectedCoinStats;
        
        if (selectedCoin == null) {
          return const SizedBox.shrink();
        }
        
        return Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                _buildStatRow(
                  context, 
                  'Market Cap', 
                  formatCurrency(selectedCoin.marketCap),
                ),
                _buildStatRow(
                  context, 
                  '24h Volume', 
                  formatCurrency(selectedCoin.totalVolume),
                ),
                if (coinStats != null) ...[
                  _buildStatRow(
                    context, 
                    'Circulating Supply', 
                    '${formatNumber(coinStats['circulating_supply'] ?? 0)} ${selectedCoin.symbol}',
                  ),
                  _buildStatRow(
                    context, 
                    'All Time High', 
                    formatCurrency(coinStats['ath'] ?? 0),
                  ),
                  const Divider(),
                  Text(
                    'Price Change',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),
                  _buildPriceChangeGrid(context, coinStats),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceChangeGrid(BuildContext context, Map<String, dynamic> stats) {
    final priceChange = stats['price_change_percent'] ?? {};
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildPriceChangeChip(context, '24h', priceChange['day'] ?? 0),
        _buildPriceChangeChip(context, '7d', priceChange['week'] ?? 0),
        _buildPriceChangeChip(context, '30d', priceChange['month'] ?? 0),
        _buildPriceChangeChip(context, '1y', priceChange['year'] ?? 0),
      ],
    );
  }
  
  Widget _buildPriceChangeChip(BuildContext context, String period, double change) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final sign = isPositive ? '+' : '';
    
    return Chip(
      label: Text(
        '$period: $sign${change.toStringAsFixed(2)}%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }
}
