import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart'; // Ensure your API service handles GET endpoints

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> trackedSymbols = [
    {"symbol": "NIFTY", "name": "NIFTY 50", "type": "index"},
    {"symbol": "BANKNIFTY", "name": "BANK NIFTY", "type": "index"},
    {"symbol": "TATSILV", "name": "TATASILV", "type": "stock"},
    {"symbol": "ADANIGREEN", "name": "ADANIGREEN", "type": "stock"},
    {"symbol": "RELIANCE", "name": "RELIANCE", "type": "stock"},
    {"symbol": "TCS", "name": "TCS", "type": "stock"},
    {"symbol": "HINDCOPPER", "name": "HINDCOPPER", "type": "stock"},
  ];

  Map<String, Map<String, dynamic>> marketData = {};

  // These variables hold the user's real financial data
  double availableBalance = 100000.0; // Default initialization
  double totalNetWorth = 100000.0;
  List<dynamic> userPortfolio = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
    _loadUserData(); // Load wallet and portfolio data
  }

  // Fetch User Balance & Portfolio from Firebase/API
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Replace '/account_status' with your actual backend route
      // Or use your firebase firestore query method here
      final data = await ApiService.getAccountStatus();

      setState(() {
        availableBalance = data['cash_available'] ?? 100000.0;
        totalNetWorth = data['total_net_worth'] ?? 100000.0;
        userPortfolio = data['portfolio'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMarketData() async {
    setState(() => isLoading = true);

    for (var item in trackedSymbols) {
      final symbol = item["symbol"] as String;
      try {
        final currentPrice = await ApiService.getLTP(symbol);
        marketData[symbol] = {
          "price": currentPrice.toStringAsFixed(2),
          "change": 0.0, // Implement percentage change logic here if needed
        };
      } catch (e) {
        debugPrint("Failed to fetch $symbol: $e");
      }
    }
    setState(() => isLoading = false);
  }

  // Function to refresh balance when a trade happens
  Future<void> _refreshBalance() async {
    // Call this after Buy/Sell completes
    await _loadUserData();
    _fetchMarketData();
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glassAppBar(),
                  const SizedBox(height: 20),

                  /// UPDATED SUMMARY CARD TO SHOW REAL DATA
                  summaryCard(availableBalance, totalNetWorth),

                  const SizedBox(height: 24),

                  const Text(
                    "Your Positions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// PORTFOLIO LIST SECTION
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (userPortfolio.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "No active positions",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userPortfolio.length,
                      itemBuilder: (context, index) {
                        final pos = userPortfolio[index];
                        final symbolName = pos["symbol"];
                        final qty = pos["quantity"];
                        final avgPrice = pos["avg_price"];

                        // Find live price for comparison
                        final livePriceStr =
                            marketData[symbolName]?['price'] ?? "—";
                        // ignore: unnecessary_cast
                        final livePrice = (livePriceStr == "—"
                            ? 0.0
                            : double.tryParse(livePriceStr) ?? 0.0) as double;

                        return CardWidget(
                          symbol: symbolName,
                          qty: qty,
                          avgPrice: avgPrice,
                          currentPrice: livePrice,
                        );
                      },
                    ),

                  const SizedBox(height: 24),
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

// --- CUSTOM WIDGETS ---

Widget summaryCard(double balance, double netWorth) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AVAILABLE BALANCE",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${balance.toStringAsFixed(2)}", // Format to local currency if needed
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            VerticalDivider(color: Colors.white24, thickness: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NET WORTH",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${netWorth.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class CardWidget extends StatelessWidget {
  final String symbol;
  final int qty;
  final double avgPrice;
  final double currentPrice;

  const CardWidget({
    super.key,
    required this.symbol,
    required this.qty,
    required this.avgPrice,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final profitLoss = (currentPrice - avgPrice) * qty;
    final isProfit = profitLoss > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$qty Qty @ ₹${avgPrice}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isProfit ? "+₹$profitLoss" : "-₹$profitLoss.abs()",
                    style: TextStyle(
                      color: isProfit ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${currentPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            ],
          ),
        ),
      ),
    );
  }
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
