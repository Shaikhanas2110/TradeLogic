import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'strategy_page.dart';

class StockDetailPage extends StatelessWidget {
  final String symbol;
  final String exchange;

  const StockDetailPage({
    super.key,
    required this.symbol,
    required this.exchange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(symbol, style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exchange, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            /// LIVE PRICE FROM BACKEND
            FutureBuilder<double>(
              future: ApiService.getPrice(symbol),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    "Loading...",
                    style: TextStyle(color: Colors.grey, fontSize: 28),
                  );
                }
                return Text(
                  "₹${snapshot.data!.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
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
                  color: const Color(0xFF121212),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  /// GO TO STRATEGY PAGE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrategyPage(symbol: symbol),
                    ),
                  );
                },
                child: const Text("CREATE STRATEGY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
