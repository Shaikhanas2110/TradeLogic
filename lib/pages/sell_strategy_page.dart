import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tradelogic/models/firebase_portfolio_service.dart';

class SellPage extends StatefulWidget {
  final Map share;
  const SellPage({super.key, required this.share});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _qtyController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _qtyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String get _symbol => widget.share['symbol']?.toString() ?? '';
  int get _available => (widget.share['quantity'] ?? 0) as int;
  double get _avgPrice => (widget.share['avg_price'] ?? 0.0).toDouble();
  double get _ltp => (widget.share['ltp'] ?? _avgPrice).toDouble();
  int get _sellQty => int.tryParse(_qtyController.text) ?? 0;
  double get _proceeds => _ltp * _sellQty;
  double get _pnl => (_ltp - _avgPrice) * _sellQty;
  bool get _isPnlPos => _pnl >= 0;
  bool get _hasValidQty => _sellQty > 0 && _sellQty <= _available;

  Color _avatarColor(String s) {
    const c = [
      Color(0xFF00C853),
      Color(0xFF448AFF),
      Color(0xFFFF6D00),
      Color(0xFFAA00FF),
      Color(0xFF00BCD4),
      Color(0xFFFF5252),
    ];
    int h = 0;
    for (var x in s.codeUnits) h = (h * 31 + x) % c.length;
    return c[h % c.length];
  }

  // ── SELL HANDLER ──────────────────────────────────────────────────────────

  Future<void> _handleSell() async {
    if (!_hasValidQty) {
      _toast("Enter a valid quantity (Max: $_available)", isSuccess: false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await FirebasePortfolioService.sellShares(
        symbol: _symbol,
        quantity: _sellQty,
        sellPrice: _ltp,
      );

      if (result['success'] == true) {
        HapticFeedback.lightImpact();
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['msg'] ?? "Sold Successfully",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        _toast(result['error'] ?? "Sell failed", isSuccess: false);
      }
    } catch (e) {
      _toast("Something went wrong", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess
            ? const Color(0xFF00C853)
            : const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setQty(int qty) {
    _qtyController.text = qty.toString();
    _qtyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _qtyController.text.length),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ac = _avatarColor(_symbol);
    final pnlClr = _isPnlPos
        ? const Color(0xFF00C853)
        : const Color(0xFFFF5252);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── WHITE HEADER ──────────────────────────────────────
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Column(
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
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: ac.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  _symbol.length >= 2
                                      ? _symbol.substring(0, 2)
                                      : _symbol,
                                  style: TextStyle(
                                    color: ac,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sell $_symbol",
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  "$_available shares available",
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // LTP badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "LTP",
                                    style: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "₹${_ltp.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A2E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── BODY ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Holdings banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0D1B2A), Color(0xFF1B2A3B)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D1B2A).withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _holdTile(
                              "Holdings",
                              "$_available shares",
                              Icons.layers_outlined,
                              const Color(0xFF448AFF),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.07),
                            ),
                            _holdTile(
                              "Avg Price",
                              "₹${_avgPrice.toStringAsFixed(2)}",
                              Icons.price_change_outlined,
                              const Color(0xFFFFAB00),
                              align: CrossAxisAlignment.center,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.07),
                            ),
                            _holdTile(
                              "Invested",
                              "₹${(_avgPrice * _available).toStringAsFixed(0)}",
                              Icons.account_balance_wallet_outlined,
                              const Color(0xFF00C853),
                              align: CrossAxisAlignment.end,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quantity input
                      _label("Quantity to Sell"),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                _qtyController.text.isNotEmpty && !_hasValidQty
                                ? const Color(0xFFFF5252).withOpacity(0.4)
                                : const Color(0xFFEEEEEE),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_sellQty > 1) _setQty(_sellQty - 1);
                              },
                              child: Container(
                                width: 48,
                                height: 56,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Color(0xFFF0F0F0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.remove_rounded,
                                  size: 20,
                                  color: Color(0xFF555F6E),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_sellQty < _available) {
                                  _setQty(_sellQty + 1);
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 56,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Color(0xFFF0F0F0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: Color(0xFF555F6E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick chips
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _chip("25%", (_available * 0.25).ceil()),
                          const SizedBox(width: 8),
                          _chip("50%", (_available * 0.5).ceil()),
                          const SizedBox(width: 8),
                          _chip("75%", (_available * 0.75).ceil()),
                          const SizedBox(width: 8),
                          _chip("Max", _available),
                        ],
                      ),

                      if (_qtyController.text.isNotEmpty && !_hasValidQty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Max quantity is $_available shares",
                            style: const TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // Order preview
                      if (_hasValidQty) ...[
                        const SizedBox(height: 24),
                        _label("Order Preview"),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _previewRow(
                                "Selling",
                                "$_sellQty of $_available shares",
                              ),
                              const Divider(
                                height: 16,
                                color: Color(0xFFF5F5F5),
                              ),
                              _previewRow(
                                "Estimated Proceeds",
                                "₹${_proceeds.toStringAsFixed(2)}",
                              ),
                              const Divider(
                                height: 16,
                                color: Color(0xFFF5F5F5),
                              ),
                              _previewRow(
                                "Realised P&L",
                                "${_isPnlPos ? '+' : ''}₹${_pnl.toStringAsFixed(2)}",
                                valueColor: pnlClr,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── CONFIRM SELL BUTTON ────────────────────────────────
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (!_hasValidQty || _isLoading)
                        ? null
                        : _handleSell,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      disabledBackgroundColor: const Color(
                        0xFFFF5252,
                      ).withOpacity(0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.sell_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasValidQty
                                    ? "Sell $_sellQty Shares"
                                    : "Confirm Sell",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET HELPERS ────────────────────────────────────────────────────────

  Widget _holdTile(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                Icon(icon, size: 11, color: iconColor),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      color: Color(0xFF555F6E),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  Widget _chip(String label, int qty) {
    final sel = _sellQty == qty;
    return GestureDetector(
      onTap: () => _setQty(qty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF5252) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? const Color(0xFFFF5252) : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : const Color(0xFF555F6E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF1A1A2E),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
