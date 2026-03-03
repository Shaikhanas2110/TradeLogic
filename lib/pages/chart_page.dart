import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tradelogic/pages/strategy_page.dart';

class ChartPage extends StatefulWidget {
  final String symbol;
  final String instrumentKey;
  final String exchange;

  const ChartPage({
    super.key,
    required this.symbol,
    required this.instrumentKey,
    required this.exchange,
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
  List<SignalPoint> signalPoints = [];

  List<String> availableStrategies = [];
  String selectedStrategy = "RSI Fibonacci";
  String currentSignal = "⚪ HOLD";

  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );

  bool isRunning = false;

  Timer? _dataTimer;
  Timer? _strategyTimer;

  @override
  void initState() {
    super.initState();
    _fetchAvailableStrategies();
    _startTimers();
    _fetchMinuteData();
    _fetchStrategySignal();
  }

  void _startTimers() {
    _dataTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchMinuteData(),
    );

    _strategyTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _fetchStrategySignal(),
    );
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _strategyTimer?.cancel();
    quantityController.dispose();
    super.dispose();
  }

  // ---------------- API CALLS ----------------

  Future<void> _fetchAvailableStrategies() async {
    try {
      final res = await http.get(
        Uri.parse("http://192.168.1.17:5000/strategies"),
      );
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
      final uri = Uri.parse(
        "http://192.168.1.17:4000/minute_data/${widget.instrumentKey}",
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
            "timestamp": dt.millisecondsSinceEpoch / 1000.0,
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
      final uri = Uri.parse("http://192.168.1.17:5000/analyze");

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

        final lastPoint = pricePoints.last;
        final newDot = SignalPoint(
          lastPoint["timestamp"],
          lastPoint["price"],
          newSignal,
        );

        setState(() {
          signalPoints.add(newDot);

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
      ),
    );
  }

  Color _getColor(String signal) {
    if (signal.contains("BUY") || signal.contains("🟢")) return Colors.green;
    if (signal.contains("SELL") || signal.contains("🔴")) return Colors.red;
    return Colors.amber;
  }

  List<FlSpot> _getSpots() =>
      pricePoints.map((e) => FlSpot(e["timestamp"], e["price"])).toList();

  List<ScatterSpot> _getDots() {
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
      return const Center(child: CircularProgressIndicator());
    }

    final spots = _getSpots();
    final dots = _getDots();

    final prices = spots.map((e) => e.y).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.9995;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.0005;
    final minX = spots.first.x;
    final maxX = spots.last.x;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- CHART ----------------
            SizedBox(
              width: double.infinity, // 🔥 Forces full available width
              height: MediaQuery.of(context).size.height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand, // 🔥 VERY IMPORTANT
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
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  final time =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        (barSpot.x * 1000).toInt(),
                                      );

                                  final timeStr = DateFormat(
                                    'HH:mm',
                                  ).format(time);

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

                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---------------- STRATEGY DROPDOWN ----------------
            const Text("Strategy", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStrategy,
                  dropdownColor: Colors.grey[900],
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStrategy = value;
                        signalPoints.clear();
                        currentSignal = "⚪ HOLD";
                      });
                      _fetchStrategySignal();
                    }
                  },
                  items: availableStrategies
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- QUANTITY ----------------
            const Text("Quantity", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),

            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- BUTTONS ----------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => isRunning = !isRunning);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isRunning ? "Stop" : "Start",
                      style: const TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StrategyPage(
                            symbol: widget.symbol,
                            exchange: widget.exchange,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Create Strategy",
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
