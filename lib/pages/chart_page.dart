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
  List<Map<String, dynamic>> pricePoints =
      []; // {"t": unix seconds, "p": price}

  Timer? _pollingTimer;
  double? currentPrice;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _fetchLatestPrice(); // initial fetch

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLatestPrice();
    });
  }

  int _get2MinBucket() {
    final now = DateTime.now();
    final flooredMinute = now.minute - (now.minute % 2);

    final bucket = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      flooredMinute,
    );

    return bucket.millisecondsSinceEpoch ~/ 1000;
  }

  Future<void> _fetchLatestPrice() async {
    try {
      final price = await ApiService.getLTP(widget.symbol);
      if (price <= 0) return;

      final bucketTime = _get2MinBucket();

      setState(() {
        currentPrice = price;
        lastUpdate = DateTime.now();

        if (pricePoints.isEmpty) {
          pricePoints.add({"t": bucketTime, "p": price});
        } else {
          final lastBucket = pricePoints.last["t"] as int;

          if (bucketTime == lastBucket) {
            // Update same 2-min candle price
            pricePoints.last["p"] = price;
          } else if (bucketTime > lastBucket) {
            // Add new 2-min point
            pricePoints.add({"t": bucketTime, "p": price});
          }
        }
      });
    } catch (e) {
      debugPrint("LTP fetch error: $e");
    }
  }

  List<FlSpot> _buildSpots() {
    return pricePoints.map((point) {
      return FlSpot((point["t"] as int).toDouble(), (point["p"] as double));
    }).toList();
  }

  String _formatTime(double x) {
    final date = DateTime.fromMillisecondsSinceEpoch(x.toInt() * 1000);
    return DateFormat('HH:mm').format(date);
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

    final spots = _buildSpots();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

    final firstPrice = spots.first.y;
    final current = currentPrice ?? spots.last.y;
    final percentChange = ((current - firstPrice) / firstPrice * 100);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Current price & change
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text(
            //         "₹${current.toStringAsFixed(2)}",
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 28,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       Container(
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 12,
            //           vertical: 6,
            //         ),
            //         decoration: BoxDecoration(
            //           color: percentChange >= 0 ? Colors.green : Colors.red,
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: Text(
            //           "${percentChange.toStringAsFixed(2)}%",
            //           style: const TextStyle(
            //             color: Colors.white,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    backgroundColor: Color(0xFFF3F4F6),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.black.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.black.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                          reservedSize: 32,
                          // IMPORTANT: no fixed interval → shows labels near real data points
                          interval: 100, // let fl_chart decide
                          getTitlesWidget: (value, meta) {
                            // Only show label if there's a nearby data point
                            final closest = pricePoints.reduce((a, b) {
                              final da = ((a["t"] as int) - value.toInt())
                                  .abs();
                              final db = ((b["t"] as int) - value.toInt())
                                  .abs();
                              return da < db ? a : b;
                            });

                            if (((closest["t"] as int) - value.toInt()).abs() >
                                300) {
                              return const SizedBox.shrink(); // hide if too far
                            }

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
                          showTitles: false,
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
                            Colors.white.withOpacity(0.75),
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                                color: Colors.black,
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

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import '../services/api_service.dart';

// class SimplePriceChart extends StatefulWidget {
//   final String symbol;

//   const SimplePriceChart({super.key, required this.symbol});

//   @override
//   State<SimplePriceChart> createState() => _SimplePriceChartState();
// }

// class _SimplePriceChartState extends State<SimplePriceChart> {
//   List<Map<String, dynamic>> pricePoints = [];

//   Timer? _pollingTimer;
//   double? currentPrice;
//   DateTime? lastUpdate;

//   @override
//   void initState() {
//     super.initState();
//     _startPolling();
//   }

//   void _startPolling() {
//     _fetchLatestPrice();

//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _fetchLatestPrice();
//     });
//   }

//   /// 🔹 This creates 2-minute bucket timestamps
//   /// 🔹 Creates 2-minute bucket timestamp
//   int _get2MinBucket() {
//     final now = DateTime.now();
//     final flooredMinute = now.minute - (now.minute % 2);

//     final bucket = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       now.hour,
//       flooredMinute,
//     );

//     return bucket.millisecondsSinceEpoch ~/ 1000;
//   }

//   Future<void> _fetchLatestPrice() async {
//     try {
//       final price = await ApiService.getLTP(widget.symbol);
//       if (price <= 0) return;

//       final bucketTime = _get2MinBucket();

//       setState(() {
//         currentPrice = price;
//         lastUpdate = DateTime.now();

//         if (pricePoints.isEmpty) {
//           pricePoints.add({"t": bucketTime, "p": price});
//         } else {
//           final lastBucket = pricePoints.last["t"] as int;

//           if (bucketTime == lastBucket) {
//             // Update same 2-min candle price
//             pricePoints.last["p"] = price;
//           } else if (bucketTime > lastBucket) {
//             // Add new 2-min point
//             pricePoints.add({"t": bucketTime, "p": price});
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("LTP fetch error: $e");
//     }
//   }

//   List<FlSpot> _buildSpots() {
//     return pricePoints
//         .map(
//           (point) =>
//               FlSpot((point["t"] as int).toDouble(), (point["p"] as double)),
//         )
//         .toList();
//   }

//   String _formatTime(double x) {
//     final date = DateTime.fromMillisecondsSinceEpoch(x.toInt() * 1000);
//     return DateFormat('HH:mm').format(date);
//   }

//   @override
//   void dispose() {
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (pricePoints.isEmpty) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: CircularProgressIndicator(color: Colors.greenAccent),
//         ),
//       );
//     }

//     final spots = _buildSpots();

//     final minX = spots.first.x;
//     final maxX = spots.last.x;
//     final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
//     final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

//     final firstPrice = spots.first.y;
//     final current = currentPrice ?? spots.last.y;
//     final percentChange = ((current - firstPrice) / firstPrice * 100);

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: LineChart(
//                   LineChartData(
//                     minX: minX,
//                     maxX: maxX,
//                     minY: minY,
//                     maxY: maxY,
//                     backgroundColor: Colors.black,
//                     gridData: FlGridData(show: false),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, meta) {
//                             return Text(
//                               _formatTime(value),
//                               style: const TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 10,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       leftTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       rightTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       topTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots: spots,
//                         isCurved: true,
//                         curveSmoothness: 0.35,
//                         color: Colors.greenAccent,
//                         barWidth: 2.5,
//                         dotData: const FlDotData(show: false),
//                         belowBarData: BarAreaData(
//                           show: true,
//                           color: Colors.green.withOpacity(0.18),
//                         ),
//                       ),
//                     ],
//                     lineTouchData: LineTouchData(
//                       enabled: true,
//                       handleBuiltInTouches: true,
//                       touchTooltipData: LineTouchTooltipData(
//                         getTooltipColor: (touchedSpot) =>
//                             Colors.black.withOpacity(0.75),
//                         getTooltipItems: (touchedSpots) {
//                           final spot = touchedSpots.first;
//                           final price = spot.y.toStringAsFixed(2);
//                           final time = _formatTime(spot.x);

//                           return [
//                             LineTooltipItem(
//                               '₹$price\n$time',
//                               const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ];
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
