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

  bool showEMA9 = true;
  bool showEMA21 = true;

  String timeframe = "1m";

  @override
  void initState() {
    super.initState();
    loadChart();
  }

  Future<void> loadChart() async {
    final data = await ApiService.getCandles(widget.symbol);

    setState(() {
      candles = data["candles"];
      ema9 = data["indicators"]["ema_9"];
      ema21 = data["indicators"]["ema_21"];
      rsi = data["indicators"]["rsi_14"];
    });
  }

  List<FlSpot> buildPriceSpots() {
    return List.generate(candles.length, (i) {
      return FlSpot(i.toDouble(), (candles[i]["c"]).toDouble());
    });
  }

  List<FlSpot> buildEMA(List list) {
    return List.generate(list.length, (i) {
      if (list[i] == null) return FlSpot(i.toDouble(), 0);
      return FlSpot(i.toDouble(), list[i].toDouble());
    });
  }

  List<FlSpot> buildRSI() {
    return List.generate(rsi.length, (i) {
      if (rsi[i] == null) return FlSpot(i.toDouble(), 0);
      return FlSpot(i.toDouble(), rsi[i].toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: candles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// Timeframe Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["1m", "5m", "15m"].map((tf) {
                    return TextButton(
                      onPressed: () {
                        setState(() => timeframe = tf);
                        loadChart();
                      },
                      child: Text(
                        tf,
                        style: TextStyle(
                          color: timeframe == tf
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                /// Price Chart
                Expanded(
                  flex: 3,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [

                        /// Price
                        LineChartBarData(
                          spots: buildPriceSpots(),
                          isCurved: true,
                          color: Colors.greenAccent,
                          dotData: const FlDotData(show: false),
                        ),

                        /// EMA 9
                        if (showEMA9)
                          LineChartBarData(
                            spots: buildEMA(ema9),
                            color: Colors.orange,
                            dotData: const FlDotData(show: false),
                          ),

                        /// EMA 21
                        if (showEMA21)
                          LineChartBarData(
                            spots: buildEMA(ema21),
                            color: Colors.blue,
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
                ),

                /// EMA Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: showEMA9,
                      onChanged: (v) => setState(() => showEMA9 = v),
                    ),
                    const Text("EMA 9", style: TextStyle(color: Colors.black)),
                    Switch(
                      value: showEMA21,
                      onChanged: (v) => setState(() => showEMA21 = v),
                    ),
                    const Text("EMA 21", style: TextStyle(color: Colors.black)),
                  ],
                ),

                /// RSI Panel
                Expanded(
                  flex: 1,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: buildRSI(),
                          color: Colors.purpleAccent,
                          dotData: const FlDotData(show: false),
                        )
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
