import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:4000";

  static Future<List<dynamic>> getWatchlist() async {
    final res = await http.get(Uri.parse("$baseUrl/watchlist"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load watchlist");
    }
  }

  static Future<double> getPrice(String symbol) async {
    final res = await http.get(Uri.parse("$baseUrl/price/$symbol"));
    return res.statusCode == 200
        ? jsonDecode(res.body)["price"].toDouble()
        : 0.0;
  }

  static Future<void> startAlgo(Map<String, dynamic> rule) async {
    await http.post(
      Uri.parse("$baseUrl/start-algo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(rule),
    );
  }

  static Future<void> stopAlgo(String symbol) async {
    await http.post(
      Uri.parse("$baseUrl/stop-algo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"symbol": symbol}),
    );
  }

  static Future<List<dynamic>> getPortfolio() async {
    final res = await http.get(Uri.parse("$baseUrl/portfolio"));
    return jsonDecode(res.body);
  }
}
