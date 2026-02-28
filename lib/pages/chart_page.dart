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
  // Data State
  List<Map<String, dynamic>> pricePoints = [];
  List<SignalPoint> signalPoints = [];

  // Strategy State
  List<String> availableStrategies = [];
  String selectedStrategy = "RSI Fibonacci";
  String currentSignal = "⚪ HOLD";

  Timer? _dataTimer;
  Timer? _strategyTimer;

  @override
  void initState() {
    super.initState();
    _fetchAvailableStrategies();
    _startTimers();
    _fetchMinuteData(); // Initial load
    _fetchStrategySignal(); // Initial load
  }

  void _startTimers() {
    // Fetch price every 60s
    _dataTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchMinuteData(),
    );
    // Fetch strategy signal every 45s
    _strategyTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _fetchStrategySignal(),
    );
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _strategyTimer?.cancel();
    super.dispose();
  }

  // --- API CALLS ---

  Future<void> _fetchAvailableStrategies() async {
    try {
      final res = await http.get(Uri.parse("http://127.0.0.1:5000/strategies"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          availableStrategies = List<String>.from(data["strategies"]);
          if (availableStrategies.isNotEmpty) {
            selectedStrategy = availableStrategies[0];
          }
        });
      }
    } catch (e) {
      debugPrint("Strategy Load Error: $e");
    }
  }

  Future<void> _fetchMinuteData() async {
    try {
      // Assuming your Node/Python data server is on port 4000
      final uri = Uri.parse(
        "http://127.0.0.1:4000/minute_data/${widget.instrumentKey}",
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> rawData = decoded is List
            ? decoded
            : (decoded["chart"] ?? []);

        if (rawData.isEmpty) return;

        List<Map<String, dynamic>> tempPoints = [];

        for (var item in rawData) {
          final timeStr = item["time"];
          final price = item["price"];

          if (timeStr == null || price == null) continue;

          // Parse HH:mm to Timestamp
          final now = DateTime.now();
          final parts = timeStr.toString().split(':');
          final dt = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          tempPoints.add({
            "timestamp": dt.millisecondsSinceEpoch / 1000.0, // Seconds
            "price": (price as num).toDouble(),
          });
        }

        if (mounted) {
          setState(() {
            pricePoints = tempPoints;
          });
        }
      }
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
    }
  }

  Future<void> _fetchStrategySignal() async {
    if (pricePoints.isEmpty) return;

    try {
      final uri = Uri.parse("http://127.0.0.1:5000/analyze");
      final body = jsonEncode({
        "symbol": widget.symbol,
        "exchange": "NSE",
        "strategy": selectedStrategy,
        "params": {"sensitivity": "Medium"},
      });

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newSignal = data["signal"];
        final reason = data["reason"];
        final confidence = data["confidence"];

        // Add dot to chart
        final lastPoint = pricePoints.last;
        final newDot = SignalPoint(
          lastPoint["timestamp"],
          lastPoint["price"],
          newSignal,
        );

        setState(() {
          signalPoints.add(newDot);

          // Only show notification if signal changed
          if (newSignal != currentSignal) {
            currentSignal = newSignal;
            _showSnackBar(newSignal, reason, confidence);
          }
        });
      }
    } catch (e) {
      debugPrint("Signal Fetch Error: $e");
    }
  }

  void _showSnackBar(String signal, String reason, int conf) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$signal: $reason ($conf%)"),
        backgroundColor: _getColor(signal),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getColor(String signal) {
    if (signal.contains("BUY") || signal.contains("🟢")) return Colors.green;
    if (signal.contains("SELL") || signal.contains("🔴")) return Colors.red;
    return Colors.amber;
  }

  // --- CHART HELPERS ---

  List<FlSpot> _getSpots() {
    return pricePoints.map((e) => FlSpot(e["timestamp"], e["price"])).toList();
  }

  List<ScatterSpot> _getDots() {
    // Show last 50 signals max
    final dots = signalPoints.length > 50
        ? signalPoints.sublist(signalPoints.length - 50)
        : signalPoints;
    return dots
        .map(
          (e) => ScatterSpot(
            e.x,
            e.y,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: _getColor(e.signal),
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final spots = _getSpots();
    final dots = _getDots();

    // Calculate Bounds
    final prices = spots.map((e) => e.y).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.9995;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.0005;
    final minX = spots.first.x;
    final maxX = spots.last.x;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.symbol),
        backgroundColor: Colors.grey[900],
        actions: [
          // STRATEGY DROPDOWN
          DropdownButton<String>(
            dropdownColor: Colors.grey[800],
            value: selectedStrategy,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedStrategy = newValue;
                  signalPoints.clear(); // Clear old strategy dots
                  currentSignal = "⚪ HOLD"; // Reset signal
                });
                _fetchStrategySignal(); // Trigger new check
              }
            },
            items: availableStrategies.map<DropdownMenuItem<String>>((
              String value,
            ) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // 1. SIGNAL DOTS
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

          // 2. LINE CHART
          LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blueAccent.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  // FIXED BRACKET ISSUE HERE
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final time = DateTime.fromMillisecondsSinceEpoch(
                        (barSpot.x * 1000).toInt(),
                      );
                      final timeStr = DateFormat('HH:mm').format(time);
                      return LineTooltipItem(
                        '₹${barSpot.y.toStringAsFixed(2)}\n$timeStr',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),

          // 3. CURRENT SIGNAL BADGE
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getColor(currentSignal),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentSignal,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
