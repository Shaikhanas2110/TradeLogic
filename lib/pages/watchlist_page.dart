import 'package:flutter/material.dart';
import 'package:tradelogic/pages/stock_detail_page.dart';
import 'package:tradelogic/services/api_service.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  late TextEditingController searchController;

  String selectedFilter = "A-Z";
  List<dynamic> allStocks = [];
  List<dynamic> filteredStocks = [];
  bool isLoading = true;

  void applyFilter() {
    setState(() {
      if (selectedFilter == "A-Z") {
        filteredStocks.sort(
          (a, b) => (a["symbol"] ?? "").compareTo(b["symbol"] ?? ""),
        );
      } else if (selectedFilter == "Price Low-High") {
        filteredStocks.sort((a, b) => (a["ltp"] ?? 0).compareTo(b["ltp"] ?? 0));
      } else if (selectedFilter == "Price High-Low") {
        filteredStocks.sort((a, b) => (b["ltp"] ?? 0).compareTo(a["ltp"] ?? 0));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

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

          // 4️⃣ DATA OK
          if (allStocks.isEmpty) {
            allStocks = snapshot.data!;
            filteredStocks = allStocks;
            isLoading = false;
          }

          return Column(
            children: [
              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Search stocks",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),

                  // 🔑 SEARCH ONLY WHEN USER PRESSES ENTER
                  onSubmitted: (query) {
                    final q = query.toLowerCase();

                    setState(() {
                      filteredStocks = allStocks.where((stock) {
                        final symbol = (stock["symbol"] ?? "")
                            .toString()
                            .toLowerCase();
                        final name = (stock["name"] ?? "")
                            .toString()
                            .toLowerCase();

                        return symbol.contains(q) || name.contains(q);
                      }).toList();
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: selectedFilter,
                      focusColor: Color(0xFFF3F4F6),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: "A-Z", child: Text("A-Z")),
                        DropdownMenuItem(
                          value: "Price Low-High",
                          child: Text("Price Low → High"),
                        ),
                        DropdownMenuItem(
                          value: "Price High-Low",
                          child: Text("Price High → Low"),
                        ),
                      ],
                      onChanged: (value) {
                        selectedFilter = value!;
                        applyFilter();
                      },
                    ),
                  ],
                ),
              ),

              // 📃 WATCHLIST
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredStocks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10), // 👈 spacing
                        itemBuilder: (context, i) {
                          final stock = filteredStocks[i];

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              title: Text(
                                stock["symbol"] ?? "",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                stock["name"] ?? "",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: FutureBuilder<double>(
                                future: ApiService.getLTP(stock["symbol"]),
                                builder: (_, snap) {
                                  if (!snap.hasData) {
                                    return const Text(
                                      "--",
                                      style: TextStyle(color: Colors.grey),
                                    );
                                  }

                                  // 🔥 Store LTP inside stock object
                                  stock["ltp"] = snap.data!;

                                  return Text(
                                    "₹${snap.data!.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StockDetailPage(
                                      symbol: stock["symbol"],
                                      exchange: stock["exchange"],
                                      instrumentKey: stock["instrument_key"],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
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
