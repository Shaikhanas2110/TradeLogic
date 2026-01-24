import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradelogic/models/portfolio_item.dart';
import 'package:tradelogic/providers/portfolio_provider.dart';
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

            Text(item.symbol, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.exchange, style: const TextStyle(color: Colors.grey)),

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
                color: item.change >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            /// Chart placeholder
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

      /// BUY BAR
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
                onPressed: () => _showBuySheet(context, price),
                child: const Text("BUY", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showSellSheet(context),
                child: const Text(
                  "SELL",
                  style: TextStyle(color: Colors.white),
                ),
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
                    /// 🔥 THIS IS STEP 5 (CORE LINE)
                    Provider.of<PortfolioProvider>(
                      context,
                      listen: false,
                    ).buyStock(
                      symbol: item.symbol,
                      exchange: item.exchange,
                      quantity: qty,
                      price: price,
                      source: TradeSource.manual,
                    );

                    Navigator.pop(context); // close bottom sheet
                    Navigator.pop(context); // back to watchlist
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

  void _showSellSheet(BuildContext context) {
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
                "Sell Quantity",
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
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  final qty = int.tryParse(qtyController.text) ?? 0;
                  if (qty > 0) {
                    try {
                      Provider.of<PortfolioProvider>(
                        context,
                        listen: false,
                      ).sellStock(symbol: item.symbol, quantity: qty);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }

                    Navigator.pop(context); // close sheet
                    Navigator.pop(context); // back
                  }
                },
                child: const Text("CONFIRM SELL"),
              ),
            ],
          ),
        );
      },
    );
  }
}
