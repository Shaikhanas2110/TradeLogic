import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tradelogic/pages/chart_page.dart';
import '../services/api_service.dart';
import 'dart:ui';

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

class _StockDetailPageState extends State<StockDetailPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          /// 🔥 DARK GRADIENT BASE
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

          /// 🔵 INDIGO GLOW (TOP RIGHT)
          Positioned(
            top: -120,
            right: -120,
            child: _buildGlowCircle(Colors.indigoAccent.withOpacity(0.6)),
          ),

          /// 🔵 INDIGO GLOW (BOTTOM LEFT)
          Positioned(
            bottom: -150,
            left: -150,
            child: _buildGlowCircle(Colors.indigo.withOpacity(0.5)),
          ),

          /// 📄 PAGE CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('images/logo1.png'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  widget.exchange,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                /// LIVE PRICE
                FutureBuilder<double>(
                  future: ApiService.getLTP(widget.symbol),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator(
                        color: Colors.indigoAccent,
                      );
                    }

                    return Text(
                      "₹${snapshot.data!.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 2),

                /// CHART CARD (Glass Style)
                Expanded(
                  child: ChartPage(
                    symbol: widget.symbol,
                    instrumentKey: widget.instrumentKey,
                    exchange: widget.exchange,
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
