import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:4000";
  // 👆 for Android emulator

  static Future<double> getLTP(String instrumentKey) async {
    final res = await http.get(
      Uri.parse("$baseUrl/ltp?instrument=$instrumentKey"),
    );
    final data = jsonDecode(res.body);
    return data["ltp"].toDouble();
  }

  static Future<bool> placeOrder({
    required String symbol,
    required String side,
    required int quantity,
    required double price,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/place-order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "symbol": symbol,
        "side": side,
        "quantity": quantity,
        "price": price,
        "order_type": "MARKET",
      }),
    );

    return res.statusCode == 200;
  }
}
