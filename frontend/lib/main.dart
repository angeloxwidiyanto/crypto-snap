import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const CryptoSnapApp());
}

class CryptoSnapApp extends StatelessWidget {
  const CryptoSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Snap',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChartPage(symbol: 'bitcoin'),
    );
  }
}

class ChartPage extends StatefulWidget {
  final String symbol;
  const ChartPage({super.key, required this.symbol});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<FlSpot> spots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final url = Uri.parse('http://localhost:8080/api/prices/${widget.symbol}');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final List<dynamic> prices = data['prices'];
      setState(() {
        spots = [
          for (int i = 0; i < prices.length; i++)
            FlSpot(i.toDouble(), (prices[i] as num).toDouble())
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} Chart')),
      body: Center(
        child: spots.isEmpty
            ? const Text('No data')
            : LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(spots: spots),
                  ],
                ),
              ),
      ),
    );
  }
}
