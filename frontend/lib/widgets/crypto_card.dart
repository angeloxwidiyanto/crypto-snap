import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/crypto_model.dart';
import '../theme/app_theme.dart';

class CryptoCard extends StatelessWidget {
  final CryptoModel coin;
  final bool isSelected;
  final VoidCallback onTap;

  const CryptoCard({
    Key? key,
    required this.coin,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.primaryColor.withOpacity(0.08))
              : (isDarkMode ? AppTheme.darkCardColor : AppTheme.lightCardColor),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Coin Logo
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: coin.image,
                placeholder: (context, url) => const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 16),
            
            // Coin Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    coin.symbol,
                    style: AppTheme.bodySmall.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Price Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${coin.currentPrice.toStringAsFixed(2)}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      coin.priceChangePercentage24h >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: coin.priceChangePercentage24h >= 0
                          ? AppTheme.accentColor
                          : AppTheme.errorColor,
                      size: 12,
                    ),
                    Text(
                      '${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                      style: AppTheme.bodySmall.copyWith(
                        color: coin.priceChangePercentage24h >= 0
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
      ),
    );
  }
}
