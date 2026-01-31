import 'package:flutter/material.dart';
import 'package:tradelogic/pages/stock_detail_page.dart';
import 'package:tradelogic/services/api_service.dart';

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
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getWatchlist(),
        builder: (context, snapshot) {
          // 1️⃣ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2️⃣ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 3️⃣ EMPTY
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No stocks found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 4️⃣ DATA OK
          final stocks = snapshot.data!;

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, i) {
              final stock = stocks[i];

              return ListTile(
                title: Text(
                  stock["symbol"],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  stock["exchange"], // ⚠️ NOT price (see next section)
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockDetailPage(
                        symbol: stock["symbol"],
                        exchange: stock["exchange"],
                      ),
                    ),
                  );
                },
              );
            },
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
