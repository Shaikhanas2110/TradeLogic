import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tradelogic/pages/chart_page.dart';
import '../services/api_service.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;
  final String exchange;
  final String instrumentKey;

  const StockDetailPage({
    super.key,
    required this.symbol,
    required this.exchange,
    required this.instrumentKey,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double? _currentPrice;
  double? _prevClose;
  bool _isPriceUp = true;

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

    _fetchPrice();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchPrice());
  }

  Future<void> _fetchPrice() async {
    try {
      // getLTPWithChange returns { "ltp": x, "prev_close": y }
      final result = await ApiService.getLTPWithChange(widget.symbol);
      final double ltp = result["ltp"] ?? 0.0;
      final double prevClose = result["prev_close"] ?? 0.0;

      if (mounted) {
        setState(() {
          _isPriceUp = _currentPrice == null || ltp >= _currentPrice!;
          _currentPrice = ltp;
          _prevClose ??= prevClose > 0 ? prevClose : null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // Real % change vs previous day close
  double get _changePct {
    if (_currentPrice == null || _prevClose == null || _prevClose == 0) {
      return 0.0;
    }
    return ((_currentPrice! - _prevClose!) / _prevClose!) * 100;
  }

  Color get _priceColor =>
      _isPriceUp ? const Color(0xFF00C853) : const Color(0xFFFF5252);

  Color get _changeColor =>
      _changePct >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF5252);

  String get _initials {
    final s = widget.symbol;
    return s.length >= 2 ? s.substring(0, 2) : s;
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
    final avatarColor = _avatarColor(widget.symbol);
    final double pct = _changePct;
    final bool pctPos = pct >= 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // ── TOP WHITE HEADER ──────────────────────────────────
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: Color(0xFF1A1A2E),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            _headerIconBtn(Icons.notifications_none_rounded),
                            const SizedBox(width: 6),
                            _headerIconBtn(Icons.ios_share_rounded),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: avatarColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: TextStyle(
                                    color: avatarColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.symbol,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A2E),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F0F0),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          widget.exchange,
                                          style: const TextStyle(
                                            color: Color(0xFF555F6E),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00C853),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        "Live",
                                        style: TextStyle(
                                          color: Color(0xFF00C853),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Live Price + % change
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Animated price
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                      ),
                                  child: _currentPrice == null
                                      ? _shimmerBox(90, 28)
                                      : Text(
                                          "₹${_currentPrice!.toStringAsFixed(2)}",
                                          key: ValueKey(_currentPrice),
                                          style: const TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 4),

                                // % change badge — real value now
                                if (_currentPrice != null)
                                  _prevClose == null
                                      ? _shimmerBox(70, 22)
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _changeColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                pctPos
                                                    ? Icons
                                                          .arrow_drop_up_rounded
                                                    : Icons
                                                          .arrow_drop_down_rounded,
                                                size: 16,
                                                color: _changeColor,
                                              ),
                                              Text(
                                                "${pct.abs().toStringAsFixed(2)}%",
                                                style: TextStyle(
                                                  color: _changeColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CHART SECTION ─────────────────────────────────────
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F6FA),
                  child: ChartPage(
                    symbol: widget.symbol,
                    instrumentKey: widget.instrumentKey,
                    exchange: widget.exchange,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── BUY / SELL BOTTOM BAR ──────────────────────────────────
        // bottomNavigationBar: Container(
        //   color: Colors.white,
        //   padding: EdgeInsets.only(
        //     left: 20,
        //     right: 20,
        //     top: 12,
        //     bottom: MediaQuery.of(context).padding.bottom + 12,
        //   ),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: _actionButton(
        //           label: "BUY",
        //           color: const Color(0xFF00C853),
        //           onTap: () {},
        //         ),
        //       ),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: _actionButton(
        //           label: "SELL",
        //           color: const Color(0xFFFF5252),
        //           onTap: () {},
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
