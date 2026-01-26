import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlgoOrderPage extends StatefulWidget {
  final String symbol;
  final String instrumentKey;

  const AlgoOrderPage({
    super.key,
    required this.symbol,
    required this.instrumentKey,
  });

  @override
  State<AlgoOrderPage> createState() => _AlgoOrderPageState();
}

class _AlgoOrderPageState extends State<AlgoOrderPage> {
  double? ltp;
  final qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLTP();
  }

  void loadLTP() async {
    final price = await ApiService.getLTP(widget.instrumentKey);
    setState(() => ltp = price);
  }

  void place(String side) async {
    final qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0 || ltp == null) return;

    final success = await ApiService.placeOrder(
      symbol: widget.symbol,
      side: side,
      quantity: qty,
      price: ltp!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Order placed successfully" : "Order failed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.symbol),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              ltp == null ? "Loading..." : "₹${ltp!.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.white, fontSize: 32),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Quantity",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => place("BUY"),
                    child: const Text("BUY"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => place("SELL"),
                    child: const Text("SELL"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
