import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StrategyPage extends StatelessWidget {
  final String symbol;
  StrategyPage({required this.symbol});

  final buyCtrl = TextEditingController();
  final sellCtrl = TextEditingController();
  final slCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Create Strategy")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field("Buy Price", buyCtrl),
            _field("Sell Price", sellCtrl),
            _field("Stop Loss", slCtrl),
            _field("Quantity", qtyCtrl),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await ApiService.startAlgo({
                  "symbol": symbol,
                  "buy_price": double.parse(buyCtrl.text),
                  "sell_price": double.parse(sellCtrl.text),
                  "stop_loss": double.parse(slCtrl.text),
                  "quantity": int.parse(qtyCtrl.text),
                });

                Navigator.pop(context);
              },
              child: const Text("START ALGO"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
