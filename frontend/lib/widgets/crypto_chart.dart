import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class CryptoChart extends StatefulWidget {
  final List<double> priceHistory;

  const CryptoChart({
    Key? key,
    required this.priceHistory,
  }) : super(key: key);

  @override
  State<CryptoChart> createState() => _CryptoChartState();
}

class _CryptoChartState extends State<CryptoChart> {
  late List<FlSpot> _spots;
  double _minY = 0;
  double _maxY = 0;
  bool _isPositive = true;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(CryptoChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.priceHistory != oldWidget.priceHistory) {
      _processData();
    }
  }

  void _processData() {
    if (widget.priceHistory.isEmpty) {
      _spots = [];
      _minY = 0;
      _maxY = 0;
      return;
    }

    // Create spots for the line chart
    _spots = List.generate(
      widget.priceHistory.length,
      (index) => FlSpot(
        index.toDouble(),
        widget.priceHistory[index],
      ),
    );

    // Find min and max values for Y axis
    _minY = widget.priceHistory.reduce((a, b) => a < b ? a : b);
    _maxY = widget.priceHistory.reduce((a, b) => a > b ? a : b);
    
    // Add some padding to min and max values
    final padding = (_maxY - _minY) * 0.1;
    _minY -= padding;
    _maxY += padding;
    
    // Determine if price trend is positive
    if (widget.priceHistory.length > 1) {
      _isPositive = widget.priceHistory.last >= widget.priceHistory.first;
    } else {
      _isPositive = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // If no data available, show a message
    if (_spots.isEmpty) {
      return const Center(
        child: Text('No price history available'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (_maxY - _minY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value % ((_maxY - _minY) / 4).round() != 0 && value != _minY && value != _maxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_spots.length - 1).toDouble(),
        minY: _minY,
        maxY: _maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '\$${touchedSpot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: _isPositive ? AppTheme.accentColor : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchLineEnd: (_, __) => double.infinity,
          getTouchedSpotIndicator: (_, spots) {
            return spots.map((LineBarSpot spot) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                  strokeWidth: 1,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: _isPositive ? AppTheme.accentColor : AppTheme.errorColor,
                      strokeWidth: 2,
                      strokeColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: LinearGradient(
              colors: [
                _isPositive ? AppTheme.accentColor : AppTheme.errorColor,
                _isPositive ? AppTheme.accentColor.withOpacity(0.8) : AppTheme.errorColor.withOpacity(0.8),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _isPositive ? AppTheme.accentColor.withOpacity(0.3) : AppTheme.errorColor.withOpacity(0.3),
                  _isPositive ? AppTheme.accentColor.withOpacity(0.0) : AppTheme.errorColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
