import 'package:flutter/material.dart';
import 'package:tradelogic/services/api_service.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: const [
            Text(
              "Portfolio",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      /// BODY
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getPortfolio(),
        builder: (context, snapshot) {
          /// 1️⃣ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// 2️⃣ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          /// 3️⃣ EMPTY PORTFOLIO
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No holdings", style: TextStyle(color: Colors.grey)),
            );
          }

          /// 4️⃣ DATA OK
          final stocks = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = stocks[i];

              /// SAFE PARSING
              final String symbol = s["symbol"] ?? "";
              final int qty = (s["quantity"] ?? 0).toInt();
              final double avg = (s["avg_price"] ?? 0).toDouble();
              final double ltp = (s["ltp"] ?? 0).toDouble();
              final double pnl = (s["pnl"] ?? 0).toDouble();

              final bool isProfit = pnl >= 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// LEFT SIDE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Qty: $qty  •  Avg: ₹${avg.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    /// RIGHT SIDE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${ltp.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${isProfit ? "+" : ""}₹${pnl.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isProfit ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
