import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradelogic/models/portfolio_item.dart';
import '../providers/portfolio_provider.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            /// Profile Avatar
            CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('images/logo.png'), // replace image
            ),

            const SizedBox(width: 12),

            /// Greeting + Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
      ),

      body: Consumer<PortfolioProvider>(
        builder: (context, portfolio, _) {
          if (portfolio.holdings.isEmpty) {
            return const Center(
              child: Text(
                "No holdings yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: portfolio.holdings.length,
            itemBuilder: (context, index) {
              final item = portfolio.holdings[index];
              final isProfit = item.pnl >= 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.symbol,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.source == TradeSource.algo ? "ALGO" : "MANUAL",
                          style: TextStyle(
                            fontSize: 12,
                            color: item.source == TradeSource.algo
                                ? Colors.orangeAccent
                                : Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Qty: ${item.quantity}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${(item.ltp * item.quantity).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${isProfit ? '+' : ''}₹${item.pnl.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: isProfit
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
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
