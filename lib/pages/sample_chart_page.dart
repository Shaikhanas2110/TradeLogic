import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  final String symbol;
  final String instrumentKey;

  const ChartPage({
    super.key,
    required this.symbol,
    required this.instrumentKey,
  });

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class SignalPoint {
  final double x;
  final double y;
  final String signal;

  SignalPoint(this.x, this.y, this.signal);
}

class _ChartPageState extends State<ChartPage> {
  List<Map<String, dynamic>> pricePoints = [];
  double? currentPrice;

  String currentSignal = 'neutral';
  DateTime? lastSignalTime;

  /// ⭐ NEW list
  List<SignalPoint> signalPoints = [];

  Timer? _priceTimer;
  Timer? _signalTimer;

  @override
  void initState() {
    super.initState();
    _startDataFetchers();
  }

  void _startDataFetchers() {
    _priceTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadMinuteData(),
    );

    _signalTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _fetchLuxSignal(),
    );

    _loadMinuteData();
    _fetchLuxSignal();
  }

  Future<void> _loadMinuteData() async {
    try {
      final uri = Uri.parse(
        "http://127.0.0.1:4000/minute_data/${widget.instrumentKey}",
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        /// ⭐ Supports BOTH old + new API
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded["chart"] ?? []);

        if (data.isEmpty) return;

        List<Map<String, dynamic>> newPoints = [];

        for (var item in data) {
          final timeStr = item["time"] as String?;
          final price = (item["price"] as num?)?.toDouble();

          if (timeStr == null || price == null) continue;

          final now = DateTime.now();
          final parts = timeStr.split(':');
          if (parts.length != 2) continue;

          final candleTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          newPoints.add({
            "timestamp": candleTime.millisecondsSinceEpoch ~/ 1000,
            "price": price,
          });
        }

        if (mounted) {
          setState(() {
            pricePoints = newPoints;
            if (newPoints.isNotEmpty) {
              currentPrice = newPoints.last["price"];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Minute data load error: $e");
    }
  }

  Future<void> _fetchLuxSignal() async {
    try {
      final uri = Uri.parse(
        "http://127.0.0.1:4000/lux_signal/${widget.instrumentKey}",
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSignal = (data['signal'] ?? 'neutral') as String;

        /// ⭐ ALWAYS ADD DOT (every API fetch)
        if (pricePoints.isNotEmpty) {
          final latest = pricePoints.last;

          signalPoints.add(
            SignalPoint(
              (latest["timestamp"] as int).toDouble(),
              latest["price"],
              newSignal,
            ),
          );
        }

        /// ⭐ Only UI change logic depends on signal change
        if (newSignal != currentSignal) {
          if (mounted) {
            setState(() {
              currentSignal = newSignal;
              lastSignalTime = DateTime.now();
            });
          }

          _showSignalSnackBar(newSignal, []);
        } else {
          /// still rebuild chart to show new dot
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Lux signal fetch error: $e");
    }
  }

  void _showSignalSnackBar(String signal, List<String> details) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(signal.toUpperCase()),
        backgroundColor: _getSignalColor(signal),
      ),
    );
  }

  /// ⭐ SIGNAL COLOR LOGIC
  Color _getSignalColor(String signal) {
    if (signal.contains('BUY') ||
        signal.contains('up') ||
        signal.contains('bull'))
      return Colors.green;

    if (signal.contains('SELL') ||
        signal.contains('down') ||
        signal.contains('bear'))
      return Colors.red;

    if (signal.contains('HOLD')) return Colors.yellow;

    return Colors.grey;
  }

  List<FlSpot> _buildPriceSpots() {
    return pricePoints.map((p) {
      return FlSpot((p["timestamp"] as int).toDouble(), p["price"] as double);
    }).toList();
  }

  /// ⭐ BUILD DOTS
  List<ScatterSpot> _buildSignalDots() {
    return signalPoints.map((s) {
      return ScatterSpot(
        s.x,
        s.y,
        dotPainter: FlDotCirclePainter(
          radius: 6,
          color: _getSignalColor(s.signal),
          strokeWidth: 0,
        ),
      );
    }).toList();
  }

  String _formatTime(double x) {
    final dt = DateTime.fromMillisecondsSinceEpoch((x * 1000).toInt());
    return DateFormat('HH:mm').format(dt);
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _signalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final spots = _buildPriceSpots();
    final dots = _buildSignalDots();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    final prices = spots.map((e) => e.y).toList();
    double minY = prices.reduce((a, b) => a < b ? a : b) * 0.98;
    double maxY = prices.reduce((a, b) => a > b ? a : b) * 1.02;
    final firstPrice = spots.first.y;
    // final lastPrice = spots.last.y;
    // final percentChange = ((lastPrice - firstPrice) / firstPrice) * 100;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ScatterChart(
            ScatterChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              scatterSpots: dots,
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),

          LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.indigo,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.indigo.withOpacity(0.14),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  getTooltipItems: (touchedSpots) {
                    final spot = touchedSpots.first;
                    final price = spot.y.toStringAsFixed(2);
                    final time = _formatTime(spot.x);
                    final pct = ((spot.y - firstPrice) / firstPrice * 100)
                        .toStringAsFixed(2);

                    return [
                      LineTooltipItem(
                        '₹$price   ${pct.startsWith('-') ? '' : '+'}$pct%\n$time',
                        const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ];
                  },
                ),
              ),
            ),
          ),
          /// ⭐ DOT OVERLAY
        ],
      ),
    );
  }
}
