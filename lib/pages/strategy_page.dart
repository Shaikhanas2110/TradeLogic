import 'package:flutter/material.dart';
import 'package:tradelogic/models/firebase_portfolio_service.dart';
import '../services/api_service.dart';

class StrategyPage extends StatefulWidget {
  final String symbol;
  final String exchange;

  const StrategyPage({super.key, required this.symbol, required this.exchange});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage>
    with SingleTickerProviderStateMixin {
  final buyCtrl = TextEditingController();
  final sellCtrl = TextEditingController();
  final slCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    buyCtrl.dispose();
    sellCtrl.dispose();
    slCtrl.dispose();
    qtyCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startAlgo() async {
    // Basic validation
    if (buyCtrl.text.isEmpty ||
        sellCtrl.text.isEmpty ||
        slCtrl.text.isEmpty ||
        qtyCtrl.text.isEmpty) {
      _showToast("Please fill all fields", isSuccess: false);
      return;
    }

    final buyPrice = double.tryParse(buyCtrl.text);
    final sellPrice = double.tryParse(sellCtrl.text);
    final stopLoss = double.tryParse(slCtrl.text);
    final quantity = int.tryParse(qtyCtrl.text);

    if (buyPrice == null ||
        sellPrice == null ||
        stopLoss == null ||
        quantity == null) {
      _showToast("Please enter valid numbers", isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.startAlgo({
        "symbol": widget.symbol,
        "exchange": widget.exchange,
        "buy_price": buyPrice,
        "sell_price": sellPrice,
        "stop_loss": stopLoss,
        "quantity": quantity,
      });

      await FirebasePortfolioService.buyShares(
        symbol: widget.symbol,
        quantity: quantity,
        price: buyPrice,
      );

      if (mounted) {
        _showToast("Strategy started successfully!", isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context);
      }
    } catch (e) {
      _showToast("Failed to start strategy", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF00C853)
            : const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── WHITE HEADER ───────────────────────────────────────
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back row
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

                    // Symbol + title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF448AFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: Color(0xFF448AFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Create Strategy",
                                style: TextStyle(
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
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      widget.symbol,
                                      style: const TextStyle(
                                        color: Color(0xFF555F6E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.exchange,
                                    style: const TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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

            // ── FORM BODY ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF448AFF).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF448AFF).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF448AFF),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "The algo will auto-execute orders when price conditions are met.",
                              style: TextStyle(
                                color: Color(0xFF448AFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── PRICE PARAMETERS ────────────────────────────
                    _sectionLabel("Price Parameters"),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          _formField(
                            controller: buyCtrl,
                            label: "Buy Price",
                            hint: "e.g. 2450.00",
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFF00C853),
                            isFirst: true,
                          ),
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFF5F5F5),
                          ),
                          _formField(
                            controller: sellCtrl,
                            label: "Sell / Target Price",
                            hint: "e.g. 2520.00",
                            icon: Icons.trending_down_rounded,
                            iconColor: const Color(0xFF448AFF),
                          ),
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFF5F5F5),
                          ),
                          _formField(
                            controller: slCtrl,
                            label: "Stop Loss",
                            hint: "e.g. 2400.00",
                            icon: Icons.shield_outlined,
                            iconColor: const Color(0xFFFF5252),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── ORDER PARAMETERS ─────────────────────────────
                    _sectionLabel("Order Parameters"),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _formField(
                        controller: qtyCtrl,
                        label: "Quantity",
                        hint: "Number of shares",
                        icon: Icons.layers_outlined,
                        iconColor: const Color(0xFFFFAB00),
                        isKeyboardInt: true,
                        isFirst: true,
                        isLast: true,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── RISK SUMMARY ─────────────────────────────────
                    _RiskSummaryCard(
                      buyCtrl: buyCtrl,
                      sellCtrl: sellCtrl,
                      slCtrl: slCtrl,
                      qtyCtrl: qtyCtrl,
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── START ALGO BUTTON ──────────────────────────────────
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
                  onPressed: _isLoading ? null : _startAlgo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    disabledBackgroundColor: const Color(
                      0xFF00C853,
                    ).withOpacity(0.5),
                    elevation: 0,
                    shadowColor: const Color(0xFF00C853).withOpacity(0.3),
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
                          children: const [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Start Algo",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
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
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF555F6E),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    bool isKeyboardInt = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: TextField(
        controller: controller,
        keyboardType: isKeyboardInt
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixText: isKeyboardInt ? "qty" : "₹",
          suffixStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
          ),
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}


class _RiskSummaryCard extends StatefulWidget {
  final TextEditingController buyCtrl;
  final TextEditingController sellCtrl;
  final TextEditingController slCtrl;
  final TextEditingController qtyCtrl;

  const _RiskSummaryCard({
    required this.buyCtrl,
    required this.sellCtrl,
    required this.slCtrl,
    required this.qtyCtrl,
  });

  @override
  State<_RiskSummaryCard> createState() => _RiskSummaryCardState();
}

class _RiskSummaryCardState extends State<_RiskSummaryCard> {
  @override
  void initState() {
    super.initState();
    widget.buyCtrl.addListener(_rebuild);
    widget.sellCtrl.addListener(_rebuild);
    widget.slCtrl.addListener(_rebuild);
    widget.qtyCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.buyCtrl.removeListener(_rebuild);
    widget.sellCtrl.removeListener(_rebuild);
    widget.slCtrl.removeListener(_rebuild);
    widget.qtyCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buy = double.tryParse(widget.buyCtrl.text) ?? 0;
    final sell = double.tryParse(widget.sellCtrl.text) ?? 0;
    final sl = double.tryParse(widget.slCtrl.text) ?? 0;
    final qty = int.tryParse(widget.qtyCtrl.text) ?? 0;

    final target = (sell - buy) * qty;
    final risk = (buy - sl) * qty;
    final rr = risk != 0 ? (target / risk) : 0.0;
    final invested = buy * qty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Risk Summary",
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  "Potential Profit",
                  target > 0 ? "+₹${target.toStringAsFixed(0)}" : "—",
                  target > 0
                      ? const Color(0xFF00C853)
                      : const Color(0xFF9E9E9E),
                ),
              ),
              Expanded(
                child: _summaryTile(
                  "Max Risk",
                  risk > 0 ? "-₹${risk.toStringAsFixed(0)}" : "—",
                  risk > 0 ? const Color(0xFFFF5252) : const Color(0xFF9E9E9E),
                  align: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _summaryTile(
                  "R:R Ratio",
                  rr > 0 ? "${rr.toStringAsFixed(2)}x" : "—",
                  rr >= 2
                      ? const Color(0xFF00C853)
                      : rr > 0
                      ? const Color(0xFFFFAB00)
                      : const Color(0xFF9E9E9E),
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Capital Required",
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
              Text(
                invested > 0 ? "₹${invested.toStringAsFixed(0)}" : "—",
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    String label,
    String value,
    Color valueColor, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
