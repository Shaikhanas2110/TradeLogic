import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tradelogic/models/firebase_portfolio_service.dart';
import 'package:tradelogic/pages/stock_detail_page.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> trackedSymbols = [
    {
      "symbol": "Nifty 50",
      "name": "NIFTY 50",
      "type": "index",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty 50",
    },
    {
      "symbol": "Nifty Bank",
      "name": "BANK NIFTY",
      "type": "index",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty Bank",
    },
    {
      "symbol": "TATSILV",
      "name": "TATASILV",
      "type": "stock",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty 50",
    },
    {
      "symbol": "ADANIGREEN",
      "name": "ADANIGREEN",
      "type": "stock",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty 50",
    },
    {
      "symbol": "RELIANCE",
      "name": "RELIANCE",
      "type": "stock",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_EQ|INE002A01018",
    },
    {
      "symbol": "TCS",
      "name": "TCS",
      "type": "stock",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty 50",
    },
    {
      "symbol": "HINDCOPPER",
      "name": "HINDCOPPER",
      "type": "stock",
      "exchange": "NSE_EQ",
      "instrument_key": "NSE_INDEX|Nifty 50",
    },
  ];

  // marketData stores: { "price": "123.45", "change": 1.23, "prev_close": 122.0 }
  Map<String, Map<String, dynamic>> marketData = {};

  double availableBalance = 100000.0;
  double totalNetWorth = 100000.0;
  List<Map<String, dynamic>> userPortfolio = [];

  StreamSubscription? _balanceSub;
  StreamSubscription? _portfolioSub;

  final user = FirebaseAuth.instance.currentUser;
  String username = "Loading...";
  bool isLoading = true;
  bool marketLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double? _currentPrice;
  double? _prevClose;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _subscribeToFirebase();
    _fetchMarketData();
    fetchUsername();
  }

  @override
  void dispose() {
    _balanceSub?.cancel();
    _portfolioSub?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ── FIREBASE STREAMS ──────────────────────────────────────────────────────

  void _subscribeToFirebase() {
    _balanceSub = FirebasePortfolioService.balanceStream().listen(
      (data) {
        if (mounted) {
          setState(() {
            availableBalance = data['cash_available'] ?? 100000.0;
            totalNetWorth = data['total_net_worth'] ?? 100000.0;
            isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint("Balance stream error: $e");
        if (mounted) setState(() => isLoading = false);
      },
    );

    _portfolioSub = FirebasePortfolioService.portfolioStream().listen((
      portfolio,
    ) {
      if (mounted) setState(() => userPortfolio = portfolio);
    }, onError: (e) => debugPrint("Portfolio stream error: $e"));
  }

  Future<void> fetchUsername() async {
    if (user == null) return;
    final ref = FirebaseDatabase.instance.ref().child("users").child(user!.uid);
    final snapshot = await ref.child("username").get();
    if (mounted) {
      setState(() {
        username = snapshot.exists ? snapshot.value.toString() : "User";
      });
    }
  }

  // ── FETCH MARKET DATA WITH REAL % CHANGE ──────────────────────────────────

  Future<void> _fetchMarketData() async {
    if (mounted) setState(() => marketLoading = true);

    // Fetch all symbols concurrently for speed
    await Future.wait(
      trackedSymbols.map((item) async {
        final symbol = item["symbol"] as String;
        try {
          // getLTPWithChange returns { "ltp": x, "prev_close": y }
          final result = await ApiService.getLTPWithChange(symbol);
          final double ltp = result["ltp"] ?? 0.0;
          final double prevClose = result["prev_close"] ?? 0.0;
          final double pct = _changePct;
          final bool pctPos = pct >= 0;
          // Calculate real % change vs previous close
          // final double changePct = prevClose > 0
          //     ? ((ltp - prevClose) / prevClose) * 100
          //     : 0.0;

          if (mounted) {
            setState(() {
              marketData[symbol] = {
                "price": ltp.toStringAsFixed(2),
                "prev_close": prevClose,
                "change": pct, // ← real % change now
              };
            });
          }
        } catch (e) {
          debugPrint("Failed to fetch $symbol: $e");
          // Keep existing data if available, or show dash
          if (mounted && !marketData.containsKey(symbol)) {
            setState(() {
              marketData[symbol] = {"price": "—", "change": 0.0};
            });
          }
        }
      }),
    );

    if (mounted) setState(() => marketLoading = false);
  }

  Future<void> _onRefresh() async {
    await _fetchMarketData();
  }

  double get _changePct {
    if (_currentPrice == null || _prevClose == null || _prevClose == 0) {
      return 0.0;
    }
    return ((_currentPrice! - _prevClose!) / _prevClose!) * 100;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: const Color(0xFF00C853),
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // ── APP BAR ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                snap: true,
                backgroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00C853).withOpacity(0.12),
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage('images/logo.png'),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _iconButton(Icons.search_rounded, () {}),
                          const SizedBox(width: 8),
                          _iconButton(Icons.notifications_none_rounded, () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── BALANCE CARD ──────────────────────────────
                    _BalanceCard(
                      balance: availableBalance,
                      netWorth: totalNetWorth,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 28),

                    // ── POSITIONS ─────────────────────────────────
                    _sectionHeader("Your Positions", onSeeAll: () {}),
                    const SizedBox(height: 12),

                    if (isLoading)
                      _skeletonList()
                    else if (userPortfolio.isEmpty)
                      _emptyPositions()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: userPortfolio.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        itemBuilder: (context, index) {
                          final pos = userPortfolio[index];
                          final symbolName = pos["symbol"]?.toString() ?? '';
                          final int qty = (pos["quantity"] ?? 0) as int;
                          final double avgPrice = (pos["avg_price"] ?? 0.0)
                              .toDouble();
                          final String livePriceStr =
                              marketData[symbolName]?['price'] ?? "—";
                          final double livePrice = livePriceStr == "—"
                              ? (pos["ltp"] ?? avgPrice).toDouble()
                              : double.tryParse(livePriceStr) ?? avgPrice;
                          return CardWidget(
                            symbol: symbolName,
                            qty: qty,
                            avgPrice: avgPrice,
                            currentPrice: livePrice,
                          );
                        },
                      ),

                    const SizedBox(height: 28),

                    // ── MARKET OVERVIEW ───────────────────────────
                    _sectionHeader("Market Overview", onSeeAll: () {}),
                    const SizedBox(height: 12),

                    if (marketLoading)
                      _marketSkeleton()
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        childAspectRatio: 1.7,
                        children: trackedSymbols.map((item) {
                          final symbol = item["symbol"] as String;
                          final data =
                              marketData[symbol] ??
                              {"price": "—", "change": 0.0};
                          return MarketCard(
                            symbol: item["name"] as String,
                            price: data["price"] as String,
                            change: (data["change"] as num).toDouble(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StockDetailPage(
                                    symbol: item["symbol"],
                                    exchange: item["exchange"],
                                    instrumentKey: item["instrument_key"],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                "See all",
                style: TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyPositions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF00C853),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "No active positions",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Start trading to see your positions here",
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          2,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _marketSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      childAspectRatio: 1.7,
      children: List.generate(
        4,
        (i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── BALANCE CARD ──
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double netWorth;
  final bool isLoading;

  const _BalanceCard({
    required this.balance,
    required this.netWorth,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2A3B)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1B2A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Portfolio Value",
                  style: TextStyle(
                    color: Color(0xFF8FA3B1),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.circle, size: 6, color: Color(0xFF00C853)),
                      SizedBox(width: 5),
                      Text(
                        "LIVE",
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? _shimmerBox(140, 32)
                : Text(
                    "₹${_formatAmount(netWorth)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _balanceTile(
                    label: "Available Balance",
                    value: isLoading ? null : "₹${_formatAmount(balance)}",
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF00C853),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.07),
                ),
                Expanded(
                  child: _balanceTile(
                    label: "Invested",
                    value: isLoading
                        ? null
                        : "₹${_formatAmount(netWorth - balance)}",
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF448AFF),
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceTile({
    required String label,
    String? value,
    required IconData icon,
    required Color iconColor,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment: align == CrossAxisAlignment.start
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8FA3B1),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        value == null
            ? _shimmerBox(80, 18)
            : Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(2)}Cr";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(2)}L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(2);
  }
}

Widget _shimmerBox(double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ── POSITION CARD ──
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
    final profitLossPct = avgPrice != 0
        ? ((currentPrice - avgPrice) / avgPrice) * 100
        : 0.0;
    final isProfit = profitLoss >= 0;
    final plColor = isProfit
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                symbol.substring(0, symbol.length.clamp(0, 2)),
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$qty shares • Avg ₹${avgPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentPrice > 0 ? "₹${currentPrice.toStringAsFixed(2)}" : "—",
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: plColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${isProfit ? '+' : ''}${profitLoss.toStringAsFixed(0)} (${profitLossPct.toStringAsFixed(1)}%)",
                  style: TextStyle(
                    color: plColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── MARKET CARD ──
class MarketCard extends StatelessWidget {
  final String symbol;
  final String price;
  final double change;
  final VoidCallback? onTap;

  const MarketCard({
    super.key,
    required this.symbol,
    required this.price,
    required this.change,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = change >= 0;
    final changeColor = isPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    symbol,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF555F6E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 14,
                        color: changeColor,
                      ),
                      Text(
                        "${change.abs().toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              price == "—" ? "—" : "₹$price",
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
