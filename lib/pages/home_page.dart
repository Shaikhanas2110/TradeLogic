import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../services/api_service.dart'; // your ApiService with getLTP

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List of symbols you want to track
  final List<Map<String, dynamic>> trackedSymbols = [
    {"symbol": "NIFTY", "name": "NIFTY 50", "type": "index"},
    {"symbol": "BANKNIFTY", "name": "BANK NIFTY", "type": "index"},
    {"symbol": "TATSILV", "name": "TATASILV", "type": "stock"},
    {"symbol": "ADANIGREEN", "name": "ADANIGREEN", "type": "stock"},
    {"symbol": "RELIANCE", "name": "RELIANCE", "type": "stock"},
    {"symbol": "TCS", "name": "TCS", "type": "stock"},
    {"symbol": "HINDCOPPER", "name": "HINDCOPPER", "type": "stock"},
  ];

  // Store fetched data: symbol → {price, change}
  Map<String, Map<String, dynamic>> marketData = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Map<String, double> previousPrices = {};

  Future<void> _fetchMarketData() async {
    setState(() => isLoading = true);

    for (var item in trackedSymbols) {
      final symbol = item["symbol"] as String;

      try {
        final currentPrice = await ApiService.getLTP(symbol);

        double changePercent = 0.0;

        // Calculate real change if we have previous price
        if (previousPrices.containsKey(symbol)) {
          final prev = previousPrices[symbol]!;
          if (prev > 0) {
            changePercent = ((currentPrice - prev) / prev) * 100;
          }
        }

        // Update previous price for next time
        previousPrices[symbol] = currentPrice;

        marketData[symbol] = {
          "price": currentPrice.toStringAsFixed(2),
          "change": changePercent,
        };
      } catch (e) {
        debugPrint("Failed to fetch $symbol: $e");
        marketData[symbol] = {"price": "—", "change": 0.0};
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// 🔥 DARK GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF0F0F1A),
                  Color(0xFF1A1A2E),
                ],
              ),
            ),
          ),

          /// Glow effects (unchanged)
          Positioned(
            top: -120,
            right: -120,
            child: _buildGlowCircle(Colors.indigoAccent.withOpacity(0.6)),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: _buildGlowCircle(Colors.indigo.withOpacity(0.5)),
          ),

          /// 📄 MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glassAppBar(),
                  const SizedBox(height: 20),
                  summaryCard(),
                  const SizedBox(height: 20),

                  const Text(
                    "Market Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: trackedSymbols.map((item) {
                            final symbol = item["symbol"] as String;
                            final data =
                                marketData[symbol] ??
                                {"price": "—", "change": 0.0};

                            return MarketCard(
                              symbol: item["name"] as String,
                              price: data["price"] as String,
                              change: data["change"] as double,
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep your MarketCard class (it's already good)
class MarketCard extends StatelessWidget {
  final String symbol;
  final String price;
  final double change;

  const MarketCard({
    super.key,
    required this.symbol,
    required this.price,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = change >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price == "—" ? "—" : "₹$price",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Placeholder for mini chart (you can add later)
              // Container(
              //   height: 40,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(8),
              //     gradient: LinearGradient(
              //       begin: Alignment.bottomLeft,
              //       end: Alignment.topRight,
              //       colors: [
              //         (isPositive ? Colors.green : Colors.red).withOpacity(
              //           0.15,
              //         ),
              //         Colors.transparent,
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget summaryCard() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "TOTAL BALANCE",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              "\$25,000",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGlowCircle(Color color) {
  return ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}

Widget _glassAppBar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: const [
          CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('images/logo.png'),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GOOD MORNING",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                "Alex Rivers",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
      ),
    ],
  );
}
