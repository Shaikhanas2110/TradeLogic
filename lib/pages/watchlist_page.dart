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
      body: FutureBuilder(
        future: ApiService.getWatchlist(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stocks = snapshot.data as List;

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, i) {
              final stock = stocks[i];
              return ListTile(
                title: Text(
                  stock["symbol"],
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "₹${stock["price"]}",
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockDetailPage(symbol: stock["symbol"],exchange: stock["exchange"],),
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
