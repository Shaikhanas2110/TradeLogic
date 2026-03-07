import 'package:flutter/material.dart';
import 'package:tradelogic/pages/stock_detail_page.dart';
import 'package:tradelogic/services/api_service.dart';
import 'dart:ui';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController searchController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String selectedFilter = "A-Z";
  List<dynamic> allStocks = [];
  List<dynamic> filteredStocks = [];
  bool isLoading = true;
  bool _isSearchFocused = false;
  final FocusNode _searchFocus = FocusNode();

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _searchFocus.addListener(() {
      setState(() => _isSearchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _fadeController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<List<dynamic>>(
          future: ApiService.getWatchlist(),
          builder: (context, snapshot) {
            // Init data once
            if (snapshot.hasData && allStocks.isEmpty) {
              allStocks = snapshot.data!;
              filteredStocks = List.from(allStocks);
              isLoading = false;
            }

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // ── STICKY APP BAR ─────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.white,
                  elevation: innerBoxIsScrolled ? 1 : 0,
                  shadowColor: Colors.black12,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  expandedHeight: 0,
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
                              "Watchlist",
                              style: TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        _iconButton(Icons.tune_rounded, () {}),
                      ],
                    ),
                  ),
                ),

                // ── SEARCH + FILTER (sticky below appbar) ──────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(
                    child: Container(
                      color: const Color(0xFFF5F6FA),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: Row(
                        children: [
                          // Search bar
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isSearchFocused
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFEEEEEE),
                                  width: _isSearchFocused ? 1.5 : 1,
                                ),
                                boxShadow: _isSearchFocused
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00C853,
                                          ).withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: searchController,
                                focusNode: _searchFocus,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search stocks...",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFBBBBBB),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: _isSearchFocused
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFBBBBBB),
                                  ),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            searchController.clear();
                                            setState(() {
                                              filteredStocks = List.from(
                                                allStocks,
                                              );
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Color(0xFFBBBBBB),
                                          ),
                                        )
                                      : null,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (query) {
                                  final q = query.toLowerCase();
                                  setState(() {
                                    filteredStocks = allStocks.where((stock) {
                                      final symbol = (stock["symbol"] ?? "")
                                          .toString()
                                          .toLowerCase();
                                      final name = (stock["name"] ?? "")
                                          .toString()
                                          .toLowerCase();
                                      return symbol.contains(q) ||
                                          name.contains(q);
                                    }).toList();
                                  });
                                },
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
                                      return symbol.contains(q) ||
                                          name.contains(q);
                                    }).toList();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Filter button
                          _FilterDropdown(
                            value: selectedFilter,
                            onChanged: (value) {
                              setState(() {
                                selectedFilter = value!;
                                applyFilter();
                              });
                            },
                          ),
                        ],
                      ),
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

  Widget _buildBody(AsyncSnapshot<List<dynamic>> snapshot) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting &&
        allStocks.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, __) => _SkeletonTile(),
      );
    }

    // Error state
    if (snapshot.hasError && allStocks.isEmpty) {
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
              "Failed to load watchlist",
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

    // Empty state
    if (filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF00C853),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No stocks found",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Try a different search term",
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Stock count chip + list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: [
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
                  "${filteredStocks.length} stocks",
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
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: filteredStocks.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 20,
                color: Color(0xFFF5F5F5),
              ),
              itemBuilder: (context, i) {
                final stock = filteredStocks[i];
                return _WatchlistTile(
                  stock: stock,
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
                );
              },
            ),
          ),
        ),
      ],
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
}

// ── WATCHLIST TILE ────────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final dynamic stock;
  final VoidCallback onTap;

  const _WatchlistTile({required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final symbol = stock["symbol"] ?? "";
    final name = stock["name"] ?? "";
    final initials = symbol.length >= 2
        ? symbol.substring(0, 2)
        : symbol.isNotEmpty
        ? symbol[0]
        : "—";

    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF00C853).withOpacity(0.05),
      highlightColor: const Color(0xFF00C853).withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _avatarColor(symbol).withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: _avatarColor(symbol),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            // Symbol + Name
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Live Price
            FutureBuilder<double>(
              future: ApiService.getLTP(symbol),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _shimmerBox(70, 16),
                      const SizedBox(height: 5),
                      _shimmerBox(50, 12),
                    ],
                  );
                }

                stock["ltp"] = snap.data!;
                final price = snap.data!;
                // change is 0 as per original — kept same
                const double change = 0.0;
                final bool isPositive = change >= 0;
                final changeColor = isPositive
                    ? const Color(0xFF00C853)
                    : const Color(0xFFFF5252);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_drop_up_rounded
                                : Icons.arrow_drop_down_rounded,
                            size: 13,
                            color: changeColor,
                          ),
                          Text(
                            "${change.abs().toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
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
}

// ── FILTER DROPDOWN ───────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF1A1A2E),
            size: 18,
          ),
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: "A-Z", child: Text("A-Z")),
            DropdownMenuItem(
              value: "Price Low-High",
              child: Text("Low → High"),
            ),
            DropdownMenuItem(
              value: "Price High-Low",
              child: Text("High → Low"),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── SKELETON TILE ─────────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
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
                _shimmerBox(140, 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmerBox(70, 14),
              const SizedBox(height: 6),
              _shimmerBox(48, 11),
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

// ── PERSISTENT HEADER DELEGATE ────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) => true;
}

// ── STATIC WATCHLIST DATA (kept from original) ────────────────────────────────

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
