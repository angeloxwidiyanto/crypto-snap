import 'package:intl/intl.dart';

// Format number as currency (USD)
String formatCurrency(num value) {
  final formatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: value > 1000 ? 0 : 2,
  );
  return formatter.format(value);
}

// Format large numbers with abbreviation (K, M, B)
String formatNumber(num value) {
  if (value == null) return '0';
  
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  } else if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)}K';
  }
  
  return value.toString();
}

// Format percentage change
String formatPercentageChange(num value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}
