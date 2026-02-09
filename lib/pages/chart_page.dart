import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class ChartPage extends StatefulWidget {
  final String symbol;
  const ChartPage({super.key, required this.symbol});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List candles = [];
  List ema9 = [];
  List ema21 = [];
  List rsi = [];
  List tradeLogs = [];

  List<ScatterSpot> signalSpots = [];

  bool showEMA9 = true;
  bool showEMA21 = true;
  String timeframe = "1m";

  // NEW: Strategy selector
  String selectedStrategy = "None";

  final List<String> strategies = ["None", "EMA Crossover", "RSI"];

  @override
  void initState() {
    super.initState();
    loadChart();
  }

  Future<void> loadChart() async {
    try {
      final data = await ApiService.getCandles(widget.symbol);
      final logs = await ApiService.getTradeLogs(widget.symbol);

      setState(() {
        candles = data["candles"] ?? [];
        ema9 = data["indicators"]?["ema_9"] ?? [];
        ema21 = data["indicators"]?["ema_21"] ?? [];
        rsi = data["indicators"]?["rsi_14"] ?? [];
        tradeLogs = logs ?? [];

        generateStrategySignals(); // ← NEW
      });
    } catch (e) {
      debugPrint("Error loading chart: $e");
    }
  }

  // NEW: Generate Buy/Sell signals based on selected strategy
  void generateStrategySignals() {
    signalSpots.clear();
    if (candles.isEmpty || selectedStrategy == "None") return;

    if (selectedStrategy == "EMA Crossover") {
      for (int i = 1; i < candles.length; i++) {
        final prevEma9 = (i - 1 < ema9.length) ? ema9[i - 1] : null;
        final currEma9 = (i < ema9.length) ? ema9[i] : null;
        final prevEma21 = (i - 1 < ema21.length) ? ema21[i - 1] : null;
        final currEma21 = (i < ema21.length) ? ema21[i] : null;

        final close = (candles[i]["c"] as num?)?.toDouble() ?? 0;

        if (prevEma9 != null &&
            currEma9 != null &&
            prevEma21 != null &&
            currEma21 != null) {
          // Golden Cross → BUY
          if (prevEma9 <= prevEma21 && currEma9 > currEma21) {
            signalSpots.add(
              ScatterSpot(
                i.toDouble(),
                close * 0.998, // slightly below price
                dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
              ),
            );
          }
          // Death Cross → SELL
          else if (prevEma9 >= prevEma21 && currEma9 < currEma21) {
            signalSpots.add(
              ScatterSpot(
                i.toDouble(),
                close * 1.002, // slightly above price
                dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
              ),
            );
          }
        }
      }
    } else if (selectedStrategy == "RSI") {
      for (int i = 0; i < rsi.length && i < candles.length; i++) {
        final rsiVal = (rsi[i] as num?)?.toDouble();
        final close = (candles[i]["c"] as num?)?.toDouble() ?? 0;

        if (rsiVal == null) continue;

        if (rsiVal < 30) {
          // Oversold → BUY
          signalSpots.add(
            ScatterSpot(
              i.toDouble(),
              close * 0.998,
              dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
            ),
          );
        } else if (rsiVal > 70) {
          // Overbought → SELL
          signalSpots.add(
            ScatterSpot(
              i.toDouble(),
              close * 1.002,
              dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
            ),
          );
        }
      }
    }
  }

  // ... (keep your existing buildPriceSpots, buildEMA, buildRSI, getMinPrice, getMaxPrice methods unchanged)

  List<FlSpot> buildPriceSpots() {
    return List.generate(candles.length, (i) {
      final close = candles[i]["c"];
      return FlSpot(
        i.toDouble(),
        (close is num && !close.isNaN && !close.isInfinite)
            ? close.toDouble()
            : 0,
      );
    });
  }

  List<FlSpot> buildEMA(List list) {
    final spots = <FlSpot>[];
    for (int i = 0; i < list.length && i < candles.length; i++) {
      final val = list[i];
      if (val == null || val is! num) continue;
      if (val.isNaN || val.isInfinite || val <= 0) continue;
      spots.add(FlSpot(i.toDouble(), val.toDouble()));
    }
    return spots;
  }

  List<FlSpot> buildRSI() {
    final spots = <FlSpot>[];
    for (int i = 0; i < rsi.length; i++) {
      final val = rsi[i];
      if (val == null || val is! num) continue;
      if (val.isNaN || val.isInfinite) continue;
      spots.add(FlSpot(i.toDouble(), val.toDouble()));
    }
    return spots;
  }

  double getMinPrice() {
    if (candles.isEmpty) return 1.0;
    final prices = candles
        .map((c) => c["c"])
        .whereType<num>()
        .where((v) => v > 0 && !v.isNaN && !v.isInfinite)
        .toList();
    return prices.isEmpty
        ? 1.0
        : prices.reduce((a, b) => a < b ? a : b).toDouble();
  }

  double getMaxPrice() {
    if (candles.isEmpty) return 100.0;
    final prices = candles
        .map((c) => c["c"])
        .whereType<num>()
        .where((v) => v > 0 && !v.isNaN && !v.isInfinite)
        .toList();
    return prices.isEmpty
        ? 100.0
        : prices.reduce((a, b) => a > b ? a : b).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final minY = getMinPrice();
    final maxY = getMaxPrice();
    final safeMinY = minY.isFinite && minY > 0 ? minY * 0.995 : 0.0;
    final safeMaxY = maxY.isFinite && maxY > minY ? maxY * 1.005 : 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: candles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Timeframe Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["1m", "5m", "15m", "1d"].map((tf) {
                    return TextButton(
                      onPressed: () {
                        setState(() => timeframe = tf);
                        loadChart();
                      },
                      child: Text(
                        tf.toUpperCase(),
                        style: TextStyle(
                          color: timeframe == tf ? Colors.black : Colors.grey,
                          fontWeight: timeframe == tf
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // NEW: Strategy Selector
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Strategy: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedStrategy,
                          items: strategies.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStrategy = value;
                                generateStrategySignals();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Price Chart
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: candles.length.toDouble() - 1,
                          minY: safeMinY,
                          maxY: safeMaxY,
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: buildPriceSpots(),
                              isCurved: true,
                              color: Colors.greenAccent,
                              dotData: const FlDotData(show: false),
                            ),
                            if (showEMA9)
                              LineChartBarData(
                                spots: buildEMA(ema9),
                                color: Colors.orange,
                                dotData: const FlDotData(show: false),
                              ),
                            if (showEMA21)
                              LineChartBarData(
                                spots: buildEMA(ema21),
                                color: Colors.blue,
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches:
                                true, // Important for default hover/touch behavior
                            touchTooltipData: LineTouchTooltipData(
                              // Dynamic color (optional but nice)
                              getTooltipColor: (touchedSpot) =>
                                  Colors.black.withOpacity(0.75),
                              tooltipRoundedRadius:
                                  8, // or tooltipBorderRadius: BorderRadius.circular(8) if newer version
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tooltipMargin: 16,
                              fitInsideHorizontally: true,
                              fitInsideVertically:
                                  true, // Prevents tooltip from going out of bounds
                              // Show price only (focus on the main price line)
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                if (touchedSpots.isEmpty) return [];

                                // Prefer the main price line (barIndex 0 is usually the candle price)
                                final priceSpot = touchedSpots.firstWhere(
                                  (spot) => spot.barIndex == 0,
                                  orElse: () => touchedSpots
                                      .first, // fallback to any spot
                                );

                                final price = priceSpot.y.toStringAsFixed(2);

                                return [
                                  LineTooltipItem(
                                    'Price: $price',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ];
                              },
                            ),
                            // Show vertical line + dot for better feedback on hover/tap
                            getTouchedSpotIndicator:
                                (
                                  LineChartBarData barData,
                                  List<int> indicators,
                                ) {
                                  return indicators.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: Colors.grey.withOpacity(0.6),
                                        strokeWidth: 1.5,
                                      ),
                                      FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, bar, idx) =>
                                                FlDotCirclePainter(
                                                  radius: 5,
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                  strokeColor:
                                                      bar.color ??
                                                      Colors.greenAccent,
                                                ),
                                      ),
                                    );
                                  }).toList();
                                },
                            // Optional: make hover more responsive on web
                            mouseCursorResolver: (event, response) {
                              return response == null ||
                                      response.lineBarSpots == null
                                  ? MouseCursor.defer
                                  : SystemMouseCursors.precise;
                            },
                          ),
                        ),
                      ),

                      IgnorePointer(
                        child: ScatterChart(
                          ScatterChartData(
                            minX: 0,
                            maxX: candles.length.toDouble() - 1,
                            minY: safeMinY,
                            maxY: safeMaxY,
                            scatterSpots: signalSpots,
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Rest of your UI (EMA toggles, RSI chart) remains the same
                // ... (keep your existing EMA toggle and RSI Expanded block)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: showEMA9,
                        onChanged: (v) => setState(() => showEMA9 = v),
                      ),
                      const Text(
                        "EMA 9",
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: showEMA21,
                        onChanged: (v) => setState(() => showEMA21 = v),
                      ),
                      const Text(
                        "EMA 21",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // RSI Panel
                Expanded(
                  flex: 1,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: rsi.length.toDouble() - 1,
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: buildRSI(),
                          color: Colors.purpleAccent,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
