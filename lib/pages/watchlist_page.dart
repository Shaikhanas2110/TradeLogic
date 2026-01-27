import 'package:flutter/material.dart';
import 'package:tradelogic/pages/algo_order_page.dart';
import 'package:tradelogic/pages/stock_detail_page.dart';
// import 'package:tradelogic/pages/stock_detail_page.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

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
              backgroundImage: AssetImage('images/logo1.png'), // replace image
            ),

            const SizedBox(width: 12),

            /// Greeting + Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Watchlist",
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: watchlistData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = watchlistData[index];
          final isPositive = item.change >= 0;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockDetailPage(item: item) 
                  // builder: (_) => AlgoOrderPage(
                  //   symbol: item.symbol,
                  //   instrumentKey: "NSE_EQ|INE002A01018", // from CSV
                  // ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Symbol + Exchange
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.symbol,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.exchange,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  /// Price + Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.price,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${isPositive ? '+' : ''}${item.change.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WatchlistItem {
  final String symbol;
  final String exchange;
  final String price;
  final double change;

  WatchlistItem({
    required this.symbol,
    required this.exchange,
    required this.price,
    required this.change,
  });
}

final List<WatchlistItem> watchlistData = [
  WatchlistItem(
    symbol: "NIFTY 50",
    exchange: "NSE",
    price: "22,453.10",
    change: -0.21,
  ),
  WatchlistItem(
    symbol: "BANKNIFTY",
    exchange: "NSE",
    price: "48,210.40",
    change: 1.14,
  ),
  WatchlistItem(
    symbol: "RELIANCE",
    exchange: "NSE",
    price: "2,856.30",
    change: 0.78,
  ),
  WatchlistItem(
    symbol: "TCS",
    exchange: "NSE",
    price: "3,912.50",
    change: -1.02,
  ),
];
