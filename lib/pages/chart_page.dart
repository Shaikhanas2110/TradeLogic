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

class _ChartPageState extends State<ChartPage> {
  // ────────────────────────────────────────────────
  // Price data
  // ────────────────────────────────────────────────
  List<Map<String, dynamic>> pricePoints = [];
  double? currentPrice;

  // ────────────────────────────────────────────────
  // Lux Oscillator signals
  // ────────────────────────────────────────────────
  String currentSignal = 'neutral';
  DateTime? lastSignalTime;
  List<FlSpot> signalSpots = []; // for drawing arrows / markers on chart

  Timer? _priceTimer;
  Timer? _signalTimer;

  @override
  void initState() {
    super.initState();
    _startDataFetchers();
  }

  void _startDataFetchers() {
    // Price data every 60 seconds
    _priceTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadMinuteData(),
    );

    // Signal check more frequently (every 30–45s)
    _signalTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _fetchLuxSignal(),
    );

    // Initial loads
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
        final data = jsonDecode(response.body) as List<dynamic>;

        if (data.isEmpty) return;

        List<Map<String, dynamic>> newPoints = [];

        for (var item in data) {
          final timeStr = item["time"] as String; // "09:01"
          final price = (item["price"] as num?)?.toDouble() ?? 0.0;

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
        final signalsList =
            (data['signals_list'] as List<dynamic>?)?.cast<String>() ?? [];

        if (newSignal != currentSignal && newSignal != 'neutral') {
          // New signal detected → show SnackBar + add marker
          _showSignalSnackBar(newSignal, signalsList);

          // Add visual marker on the latest candle
          if (pricePoints.isNotEmpty) {
            final latestTs = pricePoints.last["timestamp"] as int;
            signalSpots.add(
              FlSpot(latestTs.toDouble(), pricePoints.last["price"]),
            );
          }

          if (mounted) {
            setState(() {
              currentSignal = newSignal;
              lastSignalTime = DateTime.now();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Lux signal fetch error: $e");
    }
  }

  void _showSignalSnackBar(String signal, List<String> details) {
    Color bgColor = Colors.grey;
    String message = "Signal: $signal";

    if (signal.contains('strong_up') || signal.contains('reversal_strong_up')) {
      bgColor = Colors.green.shade700;
      message = "STRONG BUY — Reversal Up";
    } else if (signal.contains('strong_down') ||
        signal.contains('reversal_strong_down')) {
      bgColor = Colors.red.shade700;
      message = "STRONG SELL — Reversal Down";
    } else if (signal.contains('cross_up') ||
        signal.contains('hyper_cross_up')) {
      bgColor = Colors.green.shade600;
      message = "HyperWave Bullish Cross";
    } else if (signal.contains('cross_down') ||
        signal.contains('hyper_cross_down')) {
      bgColor = Colors.orange.shade800;
      message = "HyperWave Bearish Cross";
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<FlSpot> _buildPriceSpots() {
    return pricePoints.map((p) {
      return FlSpot((p["timestamp"] as int).toDouble(), p["price"] as double);
    }).toList();
  }

  List<ScatterSpot> _buildSignalMarkers() {
    // You can customize shape, color, size per signal type later
    return signalSpots.map((spot) {
      return ScatterSpot(spot.x, spot.y);
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Loading market data...\n(Market hours: 9:00 – 15:30 IST)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final spots = _buildPriceSpots();
    if (spots.isEmpty) return const SizedBox.shrink();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    final prices = spots.map((s) => s.y).toList();
    double minY = prices.reduce((a, b) => a < b ? a : b);
    double maxY = prices.reduce((a, b) => a > b ? a : b);

    minY *= 0.98;
    maxY *= 1.02;

    final firstPrice = spots.first.y;
    // final lastPrice = spots.last.y;
    // final percentChange = ((lastPrice - firstPrice) / firstPrice) * 100;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Column(
        children: [
          // Signal status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: currentSignal.contains('strong_up')
                ? Colors.green.shade800
                : currentSignal.contains('strong_down')
                ? Colors.red.shade800
                : currentSignal.contains('cross_up')
                ? Colors.green.shade700
                : currentSignal.contains('cross_down')
                ? Colors.orange.shade800
                : Colors.grey.shade800,
            child: Text(
              "Current Signal: ${currentSignal.toUpperCase()} ${lastSignalTime != null ? '• ' + _formatRelativeTime(lastSignalTime!) : ''}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.12),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),

                  // ─── This is the important part for signal markers ───
                  extraLinesData: ExtraLinesData(
                    verticalLines: signalSpots.map((spot) {
                      final isBullish =
                          currentSignal.contains('up') ||
                          currentSignal.contains('bull') ||
                          currentSignal.contains('buy');
                      return VerticalLine(
                        x: spot.x,
                        color: isBullish
                            ? Colors.greenAccent.withOpacity(0.8)
                            : Colors.redAccent.withOpacity(0.8),
                        strokeWidth: 3,
                        dashArray: [5, 3],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: isBullish
                              ? Alignment.topCenter
                              : Alignment.bottomCenter,
                          labelResolver: (_) => isBullish ? '↑' : '↓',
                        ),
                      );
                    }).toList(),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.15,
                      color: Colors.cyanAccent,
                      barWidth: 2.2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.cyan.withOpacity(0.14),
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
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
