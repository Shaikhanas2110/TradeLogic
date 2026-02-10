import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ChartPage extends StatefulWidget {
  final String symbol;
  final dynamic instrumentKey;

  const ChartPage({
    super.key,
    required this.symbol,
    required this.instrumentKey,
  });

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

  String selectedStrategy = "None";
  final List<String> strategies = ["None", "EMA Crossover", "RSI"];

  bool isIntraday = false;

  @override
  void initState() {
    super.initState();
    loadChart();
  }

  Future<void> loadChart() async {
    try {
      isIntraday = timeframe == "1d";

      final data = await ApiService.getCandles(
        instrumentKey: widget.instrumentKey,
        timeframe: timeframe,
        isIntraday: isIntraday,
      );

      final logs = await ApiService.getTradeLogs(widget.instrumentKey);

      print("Candles loaded: ${data['candles']?.length ?? 0} items");
      if (data['candles']?.isNotEmpty == true) {
        print("First candle: ${data['candles'][0]}");
        print("Type of 't': ${data['candles'][0]['t']?.runtimeType}");
        print("Type of 'c': ${data['candles'][0]['c']?.runtimeType}");
      }

      setState(() {
        candles = data["candles"] ?? [];
        ema9 = data["indicators"]?["ema_9"] ?? [];
        ema21 = data["indicators"]?["ema_21"] ?? [];
        rsi = data["indicators"]?["rsi_14"] ?? [];
        tradeLogs = logs ?? [];

        generateStrategySignals();
      });
    } catch (e) {
      debugPrint("Error loading chart: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
    }
  }

  void generateStrategySignals() {
    signalSpots.clear();
    if (candles.isEmpty || selectedStrategy == "None") return;

    if (selectedStrategy == "EMA Crossover") {
      for (int i = 1; i < candles.length; i++) {
        final prevEma9 = (i - 1 < ema9.length) ? _toDouble(ema9[i - 1]) : null;
        final currEma9 = (i < ema9.length) ? _toDouble(ema9[i]) : null;
        final prevEma21 = (i - 1 < ema21.length)
            ? _toDouble(ema21[i - 1])
            : null;
        final currEma21 = (i < ema21.length) ? _toDouble(ema21[i]) : null;

        final close = _toDouble(candles[i]["c"]);

        if (prevEma9 != null &&
            currEma9 != null &&
            prevEma21 != null &&
            currEma21 != null) {
          if (prevEma9 <= prevEma21 && currEma9 > currEma21) {
            signalSpots.add(
              ScatterSpot(
                i.toDouble(),
                close! * 0.998,
                dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
              ),
            );
          } else if (prevEma9 >= prevEma21 && currEma9 < currEma21) {
            signalSpots.add(
              ScatterSpot(
                i.toDouble(),
                close! * 1.002,
                dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
              ),
            );
          }
        }
      }
    } else if (selectedStrategy == "RSI") {
      for (int i = 0; i < rsi.length && i < candles.length; i++) {
        final rsiVal = _toDouble(rsi[i]);
        final close = _toDouble(candles[i]["c"]);

        if (rsiVal == null) continue;

        if (rsiVal < 30) {
          signalSpots.add(
            ScatterSpot(
              i.toDouble(),
              close! * 0.998,
              dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
            ),
          );
        } else if (rsiVal > 70) {
          signalSpots.add(
            ScatterSpot(
              i.toDouble(),
              close! * 1.002,
              dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
            ),
          );
        }
      }
    }
  }

  // Safe conversion helper
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<FlSpot> buildEMA(List list) {
    final spots = <FlSpot>[];
    for (int i = 0; i < list.length && i < candles.length; i++) {
      final val = _toDouble(list[i]);
      if (val == null || val.isNaN || val.isInfinite || val <= 0) continue;
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  List<FlSpot> buildRSI() {
    final spots = <FlSpot>[];
    for (int i = 0; i < rsi.length; i++) {
      final val = _toDouble(rsi[i]);
      if (val == null || val.isNaN || val.isInfinite) continue;
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  List<FlSpot> buildPriceSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < candles.length; i++) {
      final cValue = candles[i]["c"];
      double close = 0.0;

      if (cValue is num) {
        close = cValue.toDouble();
      } else if (cValue is String) {
        close = double.tryParse(cValue) ?? 0.0;
      }

      if (close > 0) {
        spots.add(FlSpot(i.toDouble(), close));
      }
    }
    return spots;
  }

  double getMinX() {
    if (candles.isEmpty) return 0;
    final t = candles.first["t"];
    if (t is num) return t.toDouble();
    if (t is String) return double.tryParse(t) ?? 0;
    return 0;
  }

  double getMaxX() {
    if (candles.isEmpty) return 1;
    final t = candles.last["t"];
    if (t is num) return t.toDouble();
    if (t is String) return double.tryParse(t) ?? candles.length - 1;
    return candles.length - 1;
  }

  double getMinPrice() {
    if (candles.isEmpty) return 1.0;
    final prices = candles
        .map((c) => _toDouble(c["c"]))
        .whereType<double>()
        .where((v) => v > 0 && v.isFinite)
        .toList();
    return prices.isEmpty ? 1.0 : prices.reduce((a, b) => a < b ? a : b);
  }

  double getMaxPrice() {
    if (candles.isEmpty) return 100.0;
    final prices = candles
        .map((c) => _toDouble(c["c"]))
        .whereType<double>()
        .where((v) => v > 0 && v.isFinite)
        .toList();
    return prices.isEmpty ? 100.0 : prices.reduce((a, b) => a > b ? a : b);
  }

  String _formatXLabel(double value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final minY = getMinPrice();
    final maxY = getMaxPrice();
    final safeMinY = minY.isFinite && minY > 0 ? minY * 0.995 : 0.0;
    final safeMaxY = maxY.isFinite && maxY > minY ? maxY * 1.005 : 100.0;

    final minX = getMinX();
    final maxX = getMaxX();

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
                          items: strategies
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
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

                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          minX: minX,
                          maxX: maxX,
                          minY: safeMinY,
                          maxY: safeMaxY,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatXLabel(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                interval: isIntraday ? 1800 : null,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
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
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  Colors.black.withOpacity(0.75),
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tooltipMargin: 16,
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                    if (touchedSpots.isEmpty) return [];

                                    final priceSpot = touchedSpots.firstWhere(
                                      (spot) => spot.barIndex == 0,
                                      orElse: () => touchedSpots.first,
                                    );

                                    final price = priceSpot.y.toStringAsFixed(
                                      2,
                                    );
                                    final x = priceSpot.x;
                                    final time = _formatXLabel(x);

                                    return [
                                      LineTooltipItem(
                                        '$time\nPrice: $price',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ];
                                  },
                            ),
                            getTouchedSpotIndicator: (barData, indicators) {
                              return indicators.map((index) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: Colors.grey.withOpacity(0.6),
                                    strokeWidth: 1.5,
                                  ),
                                  FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, idx) =>
                                        FlDotCirclePainter(
                                          radius: 5,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor:
                                              bar.color ?? Colors.greenAccent,
                                        ),
                                  ),
                                );
                              }).toList();
                            },
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
                            minX: minX,
                            maxX: maxX,
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
