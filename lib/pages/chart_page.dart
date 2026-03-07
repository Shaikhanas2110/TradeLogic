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

class _ChartPageState extends State<ChartPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> pricePoints = [];
  List<SignalPoint> signalPoints = [];
  List<String> availableStrategies = [];
  String selectedStrategy = "RSI Fibonacci";
  String currentSignal = "⚪ HOLD";

  bool isRunning = false;
  String _lastExecutedSignal = "⚪ HOLD";

  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );
  Timer? _dataTimer;
  Timer? _strategyTimer;

  late TabController _tabController;
  final List<String> _timeframes = ["1D", "1W", "1M", "3M", "1Y"];
  int _selectedTimeframe = 0;

  final String flaskBaseUrl = "http://192.168.1.17:5000";
  final String dataUrl = "http://127.0.0.1:4000";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _timeframes.length, vsync: this);
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
    _tabController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // ── AUTOMATION ────────────────────────────────────────────────────────────

  Future<void> _executeAutoTrade(String type, double price) async {
    final String endpoint = type == "buy" ? "/buy_order" : "/sell_order";
    final int qty = int.tryParse(quantityController.text) ?? 1;
    try {
      final uri = Uri.parse("$dataUrl$endpoint");
      final payload = {
        "symbol": widget.symbol,
        "qty": qty,
        "price": price,
        "sell_price": price,
      };
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        _showTradeNotification(
          "AUTO ${type.toUpperCase()}",
          "Executed @ ₹$price. ${result['msg']}",
          type,
        );
      } else {
        debugPrint("Trade Failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("Network Error in Auto Trade: $e");
    }
  }

  void _showTradeNotification(String title, String msg, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(msg),
          ],
        ),
        backgroundColor: type == "buy"
            ? const Color(0xFF00C853)
            : const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── API CALLS ─────────────────────────────────────────────────────────────

  Future<void> _fetchAvailableStrategies() async {
    try {
      final res = await http.get(Uri.parse("$flaskBaseUrl/strategies"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          availableStrategies = List<String>.from(data["strategies"]);
          if (availableStrategies.isNotEmpty &&
              !availableStrategies.contains(selectedStrategy)) {
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
      final uri = Uri.parse("$dataUrl/minute_data/${widget.instrumentKey}");
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
        if (mounted) setState(() => pricePoints = tempPoints);
      }
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
    }
  }

  Future<void> _fetchStrategySignal() async {
    if (pricePoints.isEmpty) return;
    try {
      final uri = Uri.parse("$flaskBaseUrl/analyze");
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
        final String newSignal = data["signal"];
        final double currentPrice = (data["current_price"] as num).toDouble();
        final reason = data["reason"];
        final confidence = data["confidence"];

        setState(() {
          currentSignal = newSignal;
          signalPoints.add(
            SignalPoint(pricePoints.last["timestamp"], currentPrice, newSignal),
          );
        });

        if (isRunning && newSignal != _lastExecutedSignal) {
          if (newSignal.contains("BUY") || newSignal.contains("🟢")) {
            await _executeAutoTrade("buy", currentPrice);
            _lastExecutedSignal = newSignal;
          } else if (newSignal.contains("SELL") || newSignal.contains("🔴")) {
            await _executeAutoTrade("sell", currentPrice);
            _lastExecutedSignal = newSignal;
          } else if (newSignal.contains("HOLD")) {
            _lastExecutedSignal = "⚪ HOLD";
          }
        }

        if (newSignal != _lastExecutedSignal) {
          _showSnackBar(newSignal, reason, confidence);
        }
      }
    } catch (e) {
      debugPrint("Signal Fetch Error: $e");
    }
  }

  void _showSnackBar(String signal, String reason, int conf) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$signal: $reason ($conf%)"),
        backgroundColor: _getSignalColor(signal),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Color _getSignalColor(String signal) {
    if (signal.contains("BUY") || signal.contains("🟢"))
      return const Color(0xFF00C853);
    if (signal.contains("SELL") || signal.contains("🔴"))
      return const Color(0xFFFF5252);
    return const Color(0xFFFFAB00);
  }

  Color get _signalBgColor {
    final c = _getSignalColor(currentSignal);
    return c;
  }

  String get _signalLabel {
    if (currentSignal.contains("BUY") || currentSignal.contains("🟢"))
      return "BUY";
    if (currentSignal.contains("SELL") || currentSignal.contains("🔴"))
      return "SELL";
    return "HOLD";
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
              radius: 5,
              color: _getSignalColor(e.signal),
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        )
        .toList();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      );
    }

    final spots = _getSpots();
    final dots = _getDots();
    final prices = spots.map((e) => e.y).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.9995;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.0005;
    final minX = spots.first.x;
    final maxX = spots.last.x;

    // Chart line color based on price direction
    final firstPrice = spots.first.y;
    final lastPrice = spots.last.y;
    final isChartUp = lastPrice >= firstPrice;
    final chartColor = isChartUp
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CHART CONTAINER ───────────────────────────────────────────
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Timeframe tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: List.generate(_timeframes.length, (i) {
                      final selected = _selectedTimeframe == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTimeframe = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1A1A2E)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _timeframes[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF9E9E9E),
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Chart
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: Stack(
                    children: [
                      // Scatter dots (signals)
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
                      // Line chart
                      LineChart(
                        LineChartData(
                          minX: minX,
                          maxX: maxX,
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxY - minY) / 4,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: const Color(0xFFF0F0F0),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 52,
                                getTitlesWidget: (value, meta) => Text(
                                  "₹${value.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Color(0xFFBBBBBB),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) {
                                  final dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        (value * 1000).toInt(),
                                      );
                                  return Text(
                                    DateFormat('HH:mm').format(dt),
                                    style: const TextStyle(
                                      color: Color(0xFFBBBBBB),
                                      fontSize: 9,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: chartColor,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    chartColor.withOpacity(0.15),
                                    chartColor.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 10,
                              // tooltipBgColor: const Color(0xFF1A1A2E),
                              getTooltipItems:
                                  (
                                    List<LineBarSpot> touchedBarSpots,
                                  ) => touchedBarSpots
                                      .map(
                                        (barSpot) => LineTooltipItem(
                                          '₹${barSpot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch((barSpot.x * 1000).toInt()))}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ),

                      // Signal badge overlay
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _signalBgColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _signalBgColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _signalLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── STRATEGY + AUTOMATION SECTION ────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                const Text(
                  "Algo Strategy",
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),

                // Strategy dropdown
                _sectionLabel("Strategy"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStrategy,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF1A1A2E),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStrategy = value;
                            signalPoints.clear();
                            currentSignal = "⚪ HOLD";
                            _lastExecutedSignal = "⚪ HOLD";
                          });
                          _fetchStrategySignal();
                        }
                      },
                      items: availableStrategies
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quantity
                _sectionLabel("Quantity"),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    hintText: "Enter quantity",
                    hintStyle: const TextStyle(
                      color: Color(0xFFBBBBBB),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      size: 18,
                      color: Color(0xFF9E9E9E),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C853),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Automation status indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? const Color(0xFF00C853).withOpacity(0.08)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRunning
                          ? const Color(0xFF00C853).withOpacity(0.3)
                          : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning
                              ? const Color(0xFF00C853)
                              : const Color(0xFFBBBBBB),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isRunning
                            ? "Automation is ACTIVE — monitoring signals"
                            : "Automation is paused",
                        style: TextStyle(
                          color: isRunning
                              ? const Color(0xFF00C853)
                              : const Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        label: isRunning ? "Stop Bot" : "Start Bot",
                        icon: isRunning
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: isRunning
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF00C853),
                        onTap: () {
                          setState(() {
                            isRunning = !isRunning;
                            _lastExecutedSignal = "⚪ HOLD";
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn(
                        label: "Custom Rules",
                        icon: Icons.tune_rounded,
                        color: const Color(0xFF448AFF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StrategyPage(
                              symbol: widget.symbol,
                              exchange: widget.exchange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF555F6E),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
