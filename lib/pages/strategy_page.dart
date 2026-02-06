import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StrategyPage extends StatelessWidget {
  final String symbol;
  final String exchange;
  StrategyPage({required this.symbol,required this.exchange});

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
        title: Text("Create Strategy"),
      ),
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
                  "exchange":exchange,
                  "buy_price": double.parse(buyCtrl.text),
                  "sell_price": double.parse(sellCtrl.text),
                  "stop_loss": double.parse(slCtrl.text),
                  "quantity": int.parse(qtyCtrl.text),
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20.0),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text('Start Algo', style: TextStyle(fontSize: 18,color: Colors.white)),
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
          errorStyle: TextStyle(color: Colors.redAccent),

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
