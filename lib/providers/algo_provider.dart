import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AlgoProvider extends ChangeNotifier {
  void startAlgo({
    required String symbol,
    required String side,
    required int quantity,
    required double triggerPrice,
  }) {
    ApiService.startAlgo(
      symbol: symbol,
      side: side,
      quantity: quantity,
      triggerPrice: triggerPrice,
    );
  }
}

class ApiService {
  static const baseUrl = "http://10.0.2.2:4000"; // Android emulator

  static Future<void> startAlgo({
    required String symbol,
    required String side,
    required int quantity,
    required double triggerPrice,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/start-algo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "symbol": symbol,
        "side": side,
        "quantity": quantity,
        "trigger_price": triggerPrice,
      }),
    );
  }
}
