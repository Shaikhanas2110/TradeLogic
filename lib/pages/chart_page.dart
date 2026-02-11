// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import '../services/api_service.dart';

// class ChartPage extends StatefulWidget {
//   final String symbol;
//   final dynamic instrumentKey;

//   const ChartPage({
//     super.key,
//     required this.symbol,
//     required this.instrumentKey,
//   });

//   @override
//   State<ChartPage> createState() => _ChartPageState();
// }

// class _ChartPageState extends State<ChartPage> {
//   List candles = [];
//   List ema9 = [];
//   List ema21 = [];
//   List rsi = [];
//   List tradeLogs = [];

//   List<ScatterSpot> signalSpots = [];

//   bool showEMA9 = true;
//   bool showEMA21 = true;
//   String timeframe = "1m";

//   Timer? _ltpTimer;
//   double? _currentLTP;
//   DateTime? _lastLTPUpdate;

//   String selectedStrategy = "None";
//   final List<String> strategies = ["None", "EMA Crossover", "RSI"];

//   bool isIntraday = false;

//   double? touchedPrice;
//   double? touchedPercent;
//   String? touchedTime;

//   @override
//   void initState() {
//     super.initState();
//     loadChart();
//   }

//   Future<void> loadChart() async {
//     try {
//       isIntraday = timeframe == "1d";

//       _ltpTimer?.cancel();

//       final data = await ApiService.getCandles(
//         instrumentKey: widget.instrumentKey,
//         timeframe: timeframe,
//         isIntraday: isIntraday,
//       );

//       final logs = await ApiService.getTradeLogs(widget.instrumentKey);

//       setState(() {
//         candles = (data["candles"] ?? []).reversed.toList(); // newest on right
//         ema9 = (data["indicators"]?["ema_9"] ?? []).reversed.toList();
//         ema21 = (data["indicators"]?["ema_21"] ?? []).reversed.toList();
//         rsi = (data["indicators"]?["rsi_14"] ?? []).reversed.toList();
//         tradeLogs = logs ?? [];

//         generateStrategySignals();
//       });

//       _startLTPPolling();
//     } catch (e) {
//       debugPrint("Error loading chart: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
//     }
//   }

//   void _startLTPPolling() {
//     _ltpTimer?.cancel();
//     _ltpTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
//       try {
//         final ltp = await ApiService.getLTP(widget.symbol);
//         setState(() {
//           _currentLTP = ltp;
//           _lastLTPUpdate = DateTime.now();

//           if (candles.isNotEmpty && _currentLTP != null) {
//             final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//             candles.add({"t": now, "c": _currentLTP});
//             generateStrategySignals();
//           }
//         });
//       } catch (e) {
//         debugPrint("LTP error: $e");
//       }
//     });
//   }

//   double? _toDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is num) return value.toDouble();
//     if (value is String) return double.tryParse(value);
//     return null;
//   }

//   List<FlSpot> buildPriceSpots() {
//     final spots = <FlSpot>[];
//     for (int i = 0; i < candles.length; i++) {
//       final cValue = candles[i]["c"];
//       double close = 0.0;
//       if (cValue is num) close = cValue.toDouble();
//       if (cValue is String) close = double.tryParse(cValue) ?? 0.0;

//       if (close > 0) {
//         final t = _toDouble(candles[i]["t"]) ?? i.toDouble();
//         spots.add(FlSpot(t, close));
//       }
//     }

//     if (_currentLTP != null && _currentLTP! > 0) {
//       final now = DateTime.now().millisecondsSinceEpoch / 1000;
//       spots.add(FlSpot(now, _currentLTP!));
//     }

//     return spots;
//   }

//   void generateStrategySignals() {
//     signalSpots.clear();
//     if (candles.isEmpty || selectedStrategy == "None") return;

//     if (selectedStrategy == "EMA Crossover") {
//       for (int i = 1; i < candles.length; i++) {
//         final prevEma9 = _toDouble(ema9.length > i - 1 ? ema9[i - 1] : null);
//         final currEma9 = _toDouble(ema9.length > i ? ema9[i] : null);
//         final prevEma21 = _toDouble(ema21.length > i - 1 ? ema21[i - 1] : null);
//         final currEma21 = _toDouble(ema21.length > i ? ema21[i] : null);

//         final close = _toDouble(candles[i]["c"]);

//         // Skip if any required value is null/invalid
//         if (prevEma9 == null ||
//             currEma9 == null ||
//             prevEma21 == null ||
//             currEma21 == null ||
//             close == null) {
//           continue;
//         }

//         // Now safe to compare (all are double?)
//         if (prevEma9 <= prevEma21 && currEma9 > currEma21) {
//           // Golden Cross → BUY
//           signalSpots.add(
//             ScatterSpot(
//               i.toDouble(),
//               close * 0.998,
//               dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
//             ),
//           );
//         } else if (prevEma9 >= prevEma21 && currEma9 < currEma21) {
//           // Death Cross → SELL
//           signalSpots.add(
//             ScatterSpot(
//               i.toDouble(),
//               close * 1.002,
//               dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
//             ),
//           );
//         }
//       }
//     } else if (selectedStrategy == "RSI") {
//       for (int i = 0; i < rsi.length && i < candles.length; i++) {
//         final rsiVal = _toDouble(rsi[i]);
//         final close = _toDouble(candles[i]["c"]);

//         if (rsiVal == null || close == null) continue;

//         if (rsiVal < 30) {
//           signalSpots.add(
//             ScatterSpot(
//               i.toDouble(),
//               close * 0.998,
//               dotPainter: FlDotCirclePainter(color: Colors.green, radius: 8),
//             ),
//           );
//         } else if (rsiVal > 70) {
//           signalSpots.add(
//             ScatterSpot(
//               i.toDouble(),
//               close * 1.002,
//               dotPainter: FlDotCirclePainter(color: Colors.red, radius: 8),
//             ),
//           );
//         }
//       }
//     }
//   }

//   List<FlSpot> buildEMA(List list) {
//     final spots = <FlSpot>[];
//     for (int i = 0; i < list.length && i < candles.length; i++) {
//       final val = _toDouble(list[i]);
//       if (val == null || val.isNaN || val.isInfinite || val <= 0) continue;
//       spots.add(FlSpot(i.toDouble(), val));
//     }
//     return spots;
//   }

//   List<FlSpot> buildRSI() {
//     final spots = <FlSpot>[];
//     for (int i = 0; i < rsi.length; i++) {
//       final val = _toDouble(rsi[i]);
//       if (val == null || val.isNaN || val.isInfinite) continue;
//       spots.add(FlSpot(i.toDouble(), val));
//     }
//     return spots;
//   }

//   double getMinX() {
//     if (candles.isEmpty) return 0;
//     final t = candles.first["t"];
//     if (t is num) return t.toDouble();
//     if (t is String) return double.tryParse(t) ?? 0;
//     return 0;
//   }

//   double getMaxX() {
//     if (candles.isEmpty) return 1;
//     final t = candles.last["t"];
//     if (t is num) return t.toDouble();
//     if (t is String) return double.tryParse(t) ?? candles.length - 1;
//     return candles.length - 1;
//   }

//   double getMinPrice() {
//     if (candles.isEmpty) return 1.0;
//     final prices = candles
//         .map((c) => _toDouble(c["c"]))
//         .whereType<double>()
//         .where((v) => v > 0 && v.isFinite)
//         .toList();
//     return prices.isEmpty ? 1.0 : prices.reduce((a, b) => a < b ? a : b);
//   }

//   double getMaxPrice() {
//     if (candles.isEmpty) return 100.0;
//     final prices = candles
//         .map((c) => _toDouble(c["c"]))
//         .whereType<double>()
//         .where((v) => v > 0 && v.isFinite)
//         .toList();
//     return prices.isEmpty ? 100.0 : prices.reduce((a, b) => a > b ? a : b);
//   }

//   double getFirstPrice() {
//     if (candles.isEmpty) return 1.0;
//     return _toDouble(candles.first["c"]) ?? 1.0;
//   }

//   String _formatTime(double x) {
//     final date = DateTime.fromMillisecondsSinceEpoch(x.toInt() * 1000);
//     return DateFormat('h:mm a').format(date);
//   }

//   @override
//   void dispose() {
//     _ltpTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final minPrice = getMinPrice();
//     final maxPrice = getMaxPrice();
//     final priceRange = maxPrice - minPrice;
//     final safeMinY = minPrice - priceRange * 0.1;
//     final safeMaxY = maxPrice + priceRange * 0.1;

//     final minX = getMinX();
//     final maxX = getMaxX();

//     final firstPrice = getFirstPrice();

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: candles.isEmpty
//           ? const Center(
//               child: CircularProgressIndicator(color: Colors.greenAccent),
//             )
//           : Column(
//               children: [
//                 // Top bar - Current price + change
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: (maxPrice - firstPrice) >= 0
//                               ? Colors.green
//                               : Colors.red,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           "${((maxPrice - firstPrice) / firstPrice * 100).toStringAsFixed(2)}%",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 Expanded(
//                   child: Stack(
//                     children: [
//                       LineChart(
//                         LineChartData(
//                           minX: minX,
//                           maxX: maxX,
//                           minY: safeMinY,
//                           maxY: safeMaxY,
//                           gridData: FlGridData(
//                             show: true,
//                             drawVerticalLine: true,
//                             drawHorizontalLine: true,
//                             horizontalInterval: priceRange / 5,
//                             verticalInterval: 1800, // 30 min
//                             getDrawingHorizontalLine: (value) => FlLine(
//                               color: Colors.grey.withOpacity(0.15),
//                               strokeWidth: 1,
//                             ),
//                             getDrawingVerticalLine: (value) => FlLine(
//                               color: Colors.grey.withOpacity(0.15),
//                               strokeWidth: 1,
//                             ),
//                           ),
//                           titlesData: FlTitlesData(
//                             show: true,
//                             bottomTitles: AxisTitles(
//                               sideTitles: SideTitles(
//                                 showTitles: true,
//                                 reservedSize: 32,
//                                 interval: 1800,
//                                 getTitlesWidget: (value, meta) {
//                                   return Text(
//                                     _formatTime(value),
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 10,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             leftTitles: AxisTitles(
//                               sideTitles: SideTitles(
//                                 showTitles: true,
//                                 reservedSize: 40,
//                                 getTitlesWidget: (value, meta) {
//                                   return Text(
//                                     "₹${value.toStringAsFixed(0)}",
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 10,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             rightTitles: const AxisTitles(
//                               sideTitles: SideTitles(showTitles: false),
//                             ),
//                             topTitles: const AxisTitles(
//                               sideTitles: SideTitles(showTitles: false),
//                             ),
//                           ),
//                           borderData: FlBorderData(show: false),
//                           lineBarsData: [
//                             LineChartBarData(
//                               spots: buildPriceSpots(),
//                               isCurved: true,
//                               curveSmoothness: 0.35,
//                               color: Colors.greenAccent,
//                               barWidth: 2.5,
//                               dotData: const FlDotData(show: false),
//                               belowBarData: BarAreaData(
//                                 show: true,
//                                 color: Colors.green.withOpacity(0.18),
//                               ),
//                             ),
//                             if (showEMA9)
//                               LineChartBarData(
//                                 spots: buildEMA(ema9),
//                                 color: Colors.orange,
//                                 dotData: const FlDotData(show: false),
//                               ),
//                             if (showEMA21)
//                               LineChartBarData(
//                                 spots: buildEMA(ema21),
//                                 color: Colors.blue,
//                                 dotData: const FlDotData(show: false),
//                               ),
//                           ],
//                           lineTouchData: LineTouchData(
//                             enabled: true,
//                             handleBuiltInTouches: true,
//                             touchTooltipData: LineTouchTooltipData(
//                               getTooltipColor: (touchedSpot) =>
//                                   Colors.black.withOpacity(0.75),
//                               tooltipRoundedRadius: 12,
//                               tooltipPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 10,
//                               ),
//                               tooltipMargin: 20,
//                               fitInsideHorizontally: true,
//                               fitInsideVertically: true,
//                               getTooltipItems: (List<LineBarSpot> touchedSpots) {
//                                 if (touchedSpots.isEmpty) return [];

//                                 final spot = touchedSpots.first;
//                                 final price = spot.y.toStringAsFixed(2);
//                                 final time = _formatTime(spot.x);

//                                 final percent =
//                                     ((spot.y - firstPrice) / firstPrice * 100)
//                                         .toStringAsFixed(2);

//                                 touchedPrice = spot.y;
//                                 touchedPercent = double.tryParse(percent);
//                                 touchedTime = time;

//                                 return [
//                                   LineTooltipItem(
//                                     '₹$price (${double.parse(price) >= 0 ? '+' : ''}$percent%)\n$time',
//                                     const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ];
//                               },
//                             ),
//                             getTouchedSpotIndicator: (barData, indicators) {
//                               return indicators.map((index) {
//                                 return TouchedSpotIndicatorData(
//                                   FlLine(
//                                     color: Colors.white.withOpacity(0.5),
//                                     strokeWidth: 1.5,
//                                   ),
//                                   FlDotData(
//                                     show: true,
//                                     getDotPainter: (spot, percent, bar, idx) =>
//                                         FlDotCirclePainter(
//                                           radius: 7,
//                                           color: Colors.greenAccent,
//                                           strokeWidth: 3,
//                                           strokeColor: Colors.black,
//                                         ),
//                                   ),
//                                 );
//                               }).toList();
//                             },
//                           ),
//                         ),
//                       ),

//                       // Current price marker (optional)
//                       if (_currentLTP != null)
//                         Positioned(
//                           right: 16,
//                           top: 16,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green.withOpacity(0.8),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               "₹${_currentLTP!.toStringAsFixed(2)}",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),

//                       IgnorePointer(
//                         child: ScatterChart(
//                           ScatterChartData(
//                             minX: minX,
//                             maxX: maxX,
//                             minY: safeMinY,
//                             maxY: safeMaxY,
//                             scatterSpots: signalSpots,
//                             titlesData: const FlTitlesData(show: false),
//                             gridData: const FlGridData(show: false),
//                             borderData: FlBorderData(show: false),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Padding(
//                 //   padding: const EdgeInsets.symmetric(vertical: 8),
//                 //   child: Row(
//                 //     mainAxisAlignment: MainAxisAlignment.center,
//                 //     children: [
//                 //       Switch(
//                 //         value: showEMA9,
//                 //         onChanged: (v) => setState(() => showEMA9 = v),
//                 //       ),
//                 //       const Text(
//                 //         "EMA 9",
//                 //         style: TextStyle(color: Colors.black),
//                 //       ),
//                 //       const SizedBox(width: 16),
//                 //       Switch(
//                 //         value: showEMA21,
//                 //         onChanged: (v) => setState(() => showEMA21 = v),
//                 //       ),
//                 //       const Text(
//                 //         "EMA 21",
//                 //         style: TextStyle(color: Colors.black),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),

//                 // Expanded(
//                 //   flex: 1,
//                 //   child: LineChart(
//                 //     LineChartData(
//                 //       minX: 0,
//                 //       maxX: rsi.length.toDouble() - 1,
//                 //       minY: 0,
//                 //       maxY: 100,
//                 //       gridData: const FlGridData(show: false),
//                 //       titlesData: const FlTitlesData(show: false),
//                 //       borderData: FlBorderData(show: false),
//                 //       lineBarsData: [
//                 //         LineChartBarData(
//                 //           spots: buildRSI(),
//                 //           color: Colors.purpleAccent,
//                 //           dotData: const FlDotData(show: false),
//                 //         ),
//                 //       ],
//                 //     ),
//                 //   ),
//                 // ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/api_service.dart';

class SimplePriceChart extends StatefulWidget {
  final String symbol;

  const SimplePriceChart({super.key, required this.symbol});

  @override
  State<SimplePriceChart> createState() => _SimplePriceChartState();
}

class _SimplePriceChartState extends State<SimplePriceChart> {
  // Store price points: { "t": timestamp (seconds), "p": price }
  List<Map<String, dynamic>> pricePoints = [];

  Timer? _pollingTimer;
  double? currentPrice;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Fetch initial price immediately
    _fetchLatestPrice();

    // Then poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLatestPrice();
    });
  }

  Future<void> _fetchLatestPrice() async {
    try {
      final price = await ApiService.getLTP(widget.symbol);

      if (price <= 0) return; // skip invalid

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      setState(() {
        currentPrice = price;
        lastUpdate = DateTime.now();

        // Add new point only if time has moved forward
        if (pricePoints.isEmpty || now > (pricePoints.last["t"] as int)) {
          pricePoints.add({"t": now, "p": price});
        }
      });
    } catch (e) {
      debugPrint("LTP fetch error: $e");
    }
  }

  List<FlSpot> _buildPriceSpots() {
    return pricePoints.map((point) {
      return FlSpot((point["t"] as int).toDouble(), (point["p"] as double));
    }).toList();
  }

  double _getFirstPrice() {
    if (pricePoints.isEmpty) return 0;
    return pricePoints.first["p"] as double;
  }

  String _formatTime(double x) {
    final date = DateTime.fromMillisecondsSinceEpoch(x.toInt() * 1000);
    return DateFormat('h:mm a').format(date);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final spots = _buildPriceSpots();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

    final firstPrice = _getFirstPrice();
    final current = currentPrice ?? spots.last.y;
    final percentChange = ((current - firstPrice) / firstPrice * 100);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Current price & change
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹${current.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: percentChange >= 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${percentChange.toStringAsFixed(2)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    backgroundColor: Colors.black,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: (maxY - minY) / 5,
                      verticalInterval: 1800, // 30 minutes
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1000,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatTime(value),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              "₹${value.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: Colors.greenAccent,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.18),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            Colors.black.withOpacity(0.75),
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        tooltipMargin: 20,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) return [];

                          final spot = touchedSpots.first;
                          final price = spot.y.toStringAsFixed(2);
                          final time = _formatTime(spot.x);
                          final percent =
                              ((spot.y - firstPrice) / firstPrice * 100)
                                  .toStringAsFixed(2);

                          return [
                            LineTooltipItem(
                              '₹$price  (${percent.startsWith('-') ? '' : '+'}$percent%)\n$time',
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
                              color: Colors.white.withOpacity(0.5),
                              strokeWidth: 1.5,
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, idx) =>
                                  FlDotCirclePainter(
                                    radius: 7,
                                    color: Colors.greenAccent,
                                    strokeWidth: 3,
                                    strokeColor: Colors.black,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
