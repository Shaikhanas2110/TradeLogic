import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';
import 'watchlist_page.dart';

class StockDetailPage extends StatelessWidget {
  final WatchlistItem item;

  const StockDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final double price = double.parse(item.price.replaceAll(',', ''));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          item.symbol,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.exchange,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Text(
              "₹${item.price}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "${item.change >= 0 ? '+' : ''}${item.change}% (1D)",
              style: TextStyle(
                color: item.change >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            /// CHART PLACEHOLDER
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Chart Placeholder",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BUY / SELL BAR
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
                  _showBuySheet(context, price);
                },
                child: const Text("BUY"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuySheet(BuildContext context, double price) {
    final qtyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Buy Quantity",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Enter quantity",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  final qty = int.tryParse(qtyController.text) ?? 0;
                  if (qty > 0) {
                    portfolioItems.add(
                      PortfolioItem(
                        symbol: item.symbol,
                        exchange: item.exchange,
                        price: price,
                        quantity: qty,
                      ),
                    );
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Text("CONFIRM BUY"),
              ),
            ],
          ),
        );
      },
    );
  }
}
