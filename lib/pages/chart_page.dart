import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SimplePriceChart extends StatefulWidget {
  final String symbol;
  final String instrumentKey;

  const SimplePriceChart({
    super.key,
    required this.symbol,
    required this.instrumentKey,
  });

  @override
  State<SimplePriceChart> createState() => _SimplePriceChartState();
}

class _SimplePriceChartState extends State<SimplePriceChart> {
  List<Map<String, dynamic>> pricePoints = [];
  Timer? _refreshTimer;
  double? currentPrice;

  @override
  void initState() {
    super.initState();
    _loadMinuteData();

    // Refresh every minute
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadMinuteData(),
    );
  }

  Future<void> _loadMinuteData() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:4000/minute_data/${widget.instrumentKey}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.isEmpty) return;

        List<Map<String, dynamic>> newPoints = [];

        for (var item in data) {
          final timeStr = item["time"]; // "09:01"
          final price = (item["price"] as num).toDouble();

          final now = DateTime.now();
          final parts = timeStr.split(":");

          final dt = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          newPoints.add({"t": dt.millisecondsSinceEpoch ~/ 1000, "p": price});
        }

        setState(() {
          pricePoints = newPoints;
          currentPrice = newPoints.last["p"];
        });
      }
    } catch (e) {
      debugPrint("Minute load error: $e");
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
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (pricePoints.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "No market data available.\n(Market hours: 9:00 - 15:30)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final spots = _buildSpots();

    if (spots.isEmpty) return const SizedBox();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    final prices = spots.map((s) => s.y).toList();

    double minY = prices.reduce((a, b) => a < b ? a : b);
    double maxY = prices.reduce((a, b) => a > b ? a : b);

    minY = minY * 0.98;
    maxY = maxY * 1.02;

    if (!minY.isFinite || !maxY.isFinite) {
      minY = 0;
      maxY = 1;
    }

    final firstPrice = spots.first.y;
    final current = currentPrice ?? spots.last.y;

    final percentChange = ((current - firstPrice) / firstPrice * 100);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.1,
                        color: Colors.greenAccent,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.indigo.withOpacity(0.18),
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
                        getTooltipItems: (touchedSpots) {
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

// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// class TradingViewPriceChart extends StatefulWidget {
//   final String symbol; // e.g. "NSE:RELIANCE", "NSE:NIFTY", "NASDAQ:AAPL"
//   final String instrumentKey; // kept for compatibility, but not used here

//   const TradingViewPriceChart({
//     super.key,
//     required this.symbol,
//     required this.instrumentKey,
//   });

//   @override
//   State<TradingViewPriceChart> createState() => _TradingViewPriceChartState();
// }

// class _TradingViewPriceChartState extends State<TradingViewPriceChart> {
//   InAppWebViewController? webViewController;

//   String get _htmlString =>
//       '''
// <!DOCTYPE html>
// <html>
// <head>
//   <meta name="viewport" content="width=device-width, initial-scale=1.0">
//   <style>
//     body { margin:0; padding:0; overflow:hidden; background:#000; }
//     #tv_chart_container { height:100%; width:100%; }
//   </style>
// </head>
// <body>
//   <!-- TradingView Widget BEGIN -->
//   <div class="tradingview-widget-container" id="tv_chart_container">
//     <div class="tradingview-widget-container__widget"></div>
//     <div class="tradingview-widget-copyright">
//       <a href="https://www.tradingview.com/" rel="noopener nofollow" target="_blank">
//         <span class="blue-text">Track all markets on TradingView</span>
//       </a>
//     </div>
//   </div>
//   <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
//   {
//     autosize: true,
//     symbol: "${widget.symbol}",
//     interval: "5",
//     timezone: "Asia/Kolkata",
//     theme: "dark",
//     style: "1",
//     locale: "en",
//     toolbar_bg: "#000000",
//     enable_publishing: false,
//     hide_top_toolbar: false,
//     hide_legend: false,
//     hide_side_toolbar: false,
//     allow_symbol_change: true,
//     save_image: false,
//     calendar: false,
//     studies: [
//       "MACD@tv-basicstudies",
//       "RSI@tv-basicstudies",
//       "Stochastic@tv-basicstudies"
//     ],
//     support_host: "https://www.tradingview.com"
//   }
//   </script>
//   <!-- TradingView Widget END -->
// </body>
// </html>
//   ''';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: InAppWebView(
//                 initialData: InAppWebViewInitialData(
//                   data: _htmlString,
//                   encoding: 'utf-8',
//                   mimeType: 'text/html',
//                 ),
//                 initialOptions: InAppWebViewGroupOptions(
//                   crossPlatform: InAppWebViewOptions(
//                     javaScriptEnabled: true,
//                     javaScriptCanOpenWindowsAutomatically: true,
//                     useShouldOverrideUrlLoading: true,
//                     mediaPlaybackRequiresUserGesture: false,
//                   ),
//                   android: AndroidInAppWebViewOptions(
//                     useHybridComposition: true,
//                     allowContentAccess: true,
//                     builtInZoomControls: true,
//                     displayZoomControls: false,
//                   ),
//                   ios: IOSInAppWebViewOptions(
//                     allowsInlineMediaPlayback: true,
//                     allowsBackForwardNavigationGestures: true,
//                   ),
//                 ),
//                 onWebViewCreated: (controller) {
//                   webViewController = controller;
//                 },
//                 onLoadStart: (controller, url) {
//                   debugPrint('Started loading: $url');
//                 },
//                 onLoadStop: (controller, url) {
//                   debugPrint('Finished loading: $url');
//                 },
//                 onConsoleMessage: (controller, consoleMessage) {
//                   debugPrint('Console → ${consoleMessage.message}');
//                 },
//                 onLoadError: (controller, url, code, message) {
//                   debugPrint('Load error $code: $message');
//                 },
//               ),
//             ),

//             // Buy/Sell buttons
//             Container(
//               padding: const EdgeInsets.all(12),
//               color: Colors.grey[900],
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Buy order triggered')),
//                       );
//                     },
//                     icon: const Icon(Icons.arrow_upward, color: Colors.white),
//                     label: const Text('BUY'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green[700],
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Sell order triggered')),
//                       );
//                     },
//                     icon: const Icon(Icons.arrow_downward, color: Colors.white),
//                     label: const Text('SELL'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
