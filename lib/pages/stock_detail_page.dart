import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'strategy_page.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;
  final String exchange;

  const StockDetailPage({
    super.key,
    required this.symbol,
    required this.exchange,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: AssetImage('images/logo1.png')),
                SizedBox(width: 10),
                Text(
                  widget.symbol,
                  style: const TextStyle(color: Colors.black, fontSize: 25),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(widget.exchange, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            /// LIVE PRICE FROM BACKEND
            FutureBuilder<double>(
              future: ApiService.getLTP(widget.symbol),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return Text(
                  "₹${snapshot.data!.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            /// CHART PLACEHOLDER
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "Chart coming soon",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BUY / SELL ACTION BAR
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrategyPage(symbol: widget.symbol,exchange: widget.exchange,),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20.0),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'Create Strategy',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
