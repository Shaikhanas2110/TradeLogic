import 'package:flutter/material.dart';
import 'package:tradelogic/services/api_service.dart';
import 'package:tradelogic/pages/sell_strategy_page.dart'; // Ensure this path is correct
import 'dart:ui';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  // Key to force refresh the FutureBuilder
  Key _refreshKey = UniqueKey();

  void _refreshPortfolio() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: const [
            CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('images/logo.png'),
            ),
            SizedBox(width: 12),
            Text(
              "Portfolio",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshPortfolio,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
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

          /// 📄 CONTENT
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    key: _refreshKey, // Used to trigger reload
                    future: ApiService.getPortfolio(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.indigoAccent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No holdings",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      final stocks = snapshot.data!;

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: stocks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final s = stocks[i];
                          final String symbol = s["symbol"] ?? "";
                          final int qty = (s["quantity"] ?? 0).toInt();
                          final double avg = (s["avg_price"] ?? 0).toDouble();
                          final double ltp = (s["ltp"] ?? 0).toDouble();
                          final double pnl = (s["pnl"] ?? 0).toDouble();
                          final bool isProfit = pnl >= 0;

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        /// LEFT SIDE (Info)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              symbol,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Qty: $qty  •  Avg: ₹${avg.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// RIGHT SIDE (Price/PnL)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${ltp.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${isProfit ? "+" : ""}₹${pnl.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isProfit
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Colors.white10,
                                      height: 20,
                                    ),

                                    /// SELL BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          // Navigate to Sell Page
                                          final bool? didSell =
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SellPage(share: s),
                                                ),
                                              );
                                          // If sell happened, refresh the list
                                          if (didSell == true) {
                                            _refreshPortfolio();
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.shopping_cart_checkout,
                                          size: 18,
                                          color: Colors.orangeAccent,
                                        ),
                                        label: const Text(
                                          "SELL",
                                          style: TextStyle(
                                            color: Colors.orangeAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.orangeAccent
                                              .withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
}
