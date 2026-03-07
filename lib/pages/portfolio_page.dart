import 'package:flutter/material.dart';
import 'package:tradelogic/models/firebase_portfolio_service.dart';
import 'package:tradelogic/services/api_service.dart';
import 'package:tradelogic/pages/sell_strategy_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage>
    with SingleTickerProviderStateMixin {
  Key _refreshKey = UniqueKey();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  void _refreshPortfolio() {
    setState(() => _refreshKey = UniqueKey());
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Color _avatarColor(String symbol) {
    const colors = [
      Color(0xFF00C853),
      Color(0xFF448AFF),
      Color(0xFFFF6D00),
      Color(0xFFAA00FF),
      Color(0xFF00BCD4),
      Color(0xFFFF5252),
    ];
    int hash = 0;
    for (var ch in symbol.codeUnits) {
      hash = (hash * 31 + ch) % colors.length;
    }
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<List<dynamic>>(
          key: _refreshKey,
          future: FirebasePortfolioService.getPortfolio(),
          builder: (context, snapshot) {
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // ── APP BAR ───────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.white,
                  elevation: innerBoxIsScrolled ? 1 : 0,
                  shadowColor: Colors.black12,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
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
                                color: const Color(
                                  0xFF00C853,
                                ).withOpacity(0.12),
                              ),
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage('images/logo.png'),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Portfolio",
                              style: TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _refreshPortfolio,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── SUMMARY CARD (shown only when data is loaded) ─────
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSummaryCard(snapshot.data!)),

                // ── SECTION LABEL ─────────────────────────────────────
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Your Holdings",
                            style: TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${snapshot.data!.length} stocks",
                              style: const TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              body: _buildBody(snapshot),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<dynamic> stocks) {
    double totalInvested = 0;
    double totalCurrent = 0;
    for (final s in stocks) {
      final qty = (s["quantity"] ?? 0).toDouble();
      final avg = (s["avg_price"] ?? 0).toDouble();
      final ltp = (s["ltp"] ?? 0).toDouble();
      totalInvested += qty * avg;
      totalCurrent += qty * ltp;
    }
    final totalPnl = totalCurrent - totalInvested;
    final totalPnlPct = totalInvested != 0
        ? (totalPnl / totalInvested) * 100
        : 0.0;
    final isProfit = totalPnl >= 0;
    final pnlColor = isProfit
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
              color: const Color(0xFF0D1B2A).withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryTile(
                  label: "Invested",
                  value: "₹${_fmt(totalInvested)}",
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF448AFF),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.07),
                ),
                _summaryTile(
                  label: "Current",
                  value: "₹${_fmt(totalCurrent)}",
                  icon: Icons.show_chart_rounded,
                  iconColor: const Color(0xFF00C853),
                  align: CrossAxisAlignment.center,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.07),
                ),
                _summaryTile(
                  label: "P&L",
                  value: "${isProfit ? '+' : ''}₹${_fmt(totalPnl)}",
                  valueColor: pnlColor,
                  icon: isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  iconColor: pnlColor,
                  align: CrossAxisAlignment.end,
                  subtitle:
                      "${isProfit ? '+' : ''}${totalPnlPct.toStringAsFixed(2)}%",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    Color? valueColor,
    required IconData icon,
    required Color iconColor,
    CrossAxisAlignment align = CrossAxisAlignment.start,
    String? subtitle,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: align == CrossAxisAlignment.start
                ? MainAxisAlignment.start
                : align == CrossAxisAlignment.end
                ? MainAxisAlignment.end
                : MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8FA3B1),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<dynamic>> snapshot) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _SkeletonCard(),
      );
    }

    // Error
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFFF5252),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Failed to load portfolio",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${snapshot.error}",
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Empty
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                color: Color(0xFF00C853),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No holdings yet",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Your bought stocks will appear here",
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final stocks = snapshot.data!;

    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 72,
          endIndent: 20,
          color: Color(0xFFF5F5F5),
        ),
        itemBuilder: (context, i) {
          final s = stocks[i];
          final String symbol = s["symbol"] ?? "";
          final int qty = (s["quantity"] ?? 0).toInt();
          final double avg = (s["avg_price"] ?? 0).toDouble();
          final double ltp = (s["ltp"] ?? 0).toDouble();
          final double pnl = (s["pnl"] ?? 0).toDouble();
          final bool isProfit = pnl >= 0;
          final pnlColor = isProfit
              ? const Color(0xFF00C853)
              : const Color(0xFFFF5252);
          final pnlPct = avg != 0 ? (pnl / (avg * qty)) * 100 : 0.0;
          final avatarColor = _avatarColor(symbol);
          final initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;

          return InkWell(
            splashColor: const Color(0xFF00C853).withOpacity(0.04),
            highlightColor: const Color(0xFF00C853).withOpacity(0.02),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: avatarColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: avatarColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),

                      // Symbol + qty/avg
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
                              "$qty shares  •  Avg ₹${avg.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LTP + P&L
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${ltp.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pnlColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${isProfit ? '+' : ''}₹${pnl.toStringAsFixed(0)}  (${pnlPct.toStringAsFixed(1)}%)",
                              style: TextStyle(
                                color: pnlColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sell button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final bool? didSell = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellPage(share: s),
                          ),
                        );
                        if (didSell == true) _refreshPortfolio();
                      },
                      icon: const Icon(
                        Icons.sell_outlined,
                        size: 15,
                        color: Color(0xFFFF5252),
                      ),
                      label: const Text(
                        "SELL",
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF5252),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color(
                          0xFFFF5252,
                        ).withOpacity(0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(double amount) {
    if (amount.abs() >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(2)}Cr";
    } else if (amount.abs() >= 100000) {
      return "${(amount / 100000).toStringAsFixed(2)}L";
    } else if (amount.abs() >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(2);
  }
}

// ── SKELETON CARD ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(100, 14),
                const SizedBox(height: 6),
                _shimmerBox(150, 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmerBox(70, 14),
              const SizedBox(height: 6),
              _shimmerBox(80, 20),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _shimmerBox(double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
