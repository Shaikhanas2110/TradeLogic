import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = "http://127.0.0.1:4000";
  static const String baseUrl = "http://192.168.1.17:4000";

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
      Uri.parse("$baseUrl/start_algo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(rule),
    );
  }

  static Future<void> stopAlgo(String symbol) async {
    await http.post(
      Uri.parse("$baseUrl/stop_algo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"symbol": symbol}),
    );
  }

  static Future<double> getLTP(String symbol) async {
    final res = await http.get(Uri.parse("$baseUrl/ltp/$symbol"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["price"] ?? 0).toDouble();
    } else {
      throw Exception("Failed to fetch LTP");
    }
  }

  static Future<List<dynamic>> getPortfolio() async {
    final res = await http.get(Uri.parse("$baseUrl/portfolio"));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load portfolio");
    }
  }

  static Future<Map<String, dynamic>> getCandles({
    required dynamic instrumentKey,
    required String timeframe,
    required bool isIntraday,
  }) async {
    final interval = _mapTimeframeToInterval(timeframe);

    final uri = Uri.parse('$baseUrl/candles/$instrumentKey').replace(
      queryParameters: {
        'interval': interval,
        'intraday': isIntraday.toString(), // pass flag to backend
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception('Backend error: ${data['error']}');
    }

    return data;
  }

  static String _mapTimeframeToInterval(String timeframe) {
    switch (timeframe) {
      case "1m":
        return "1minute";
      case "5m":
        return "5minute";
      case "15m":
        return "15minute";
      case "1d":
        return "1minute"; // use 1min for intraday to show time movement
      default:
        return "1minute";
    }
  }

  static Future<List<dynamic>> getTradeLogs(String symbol) async {
    final res = await http.get(Uri.parse("$baseUrl/trade_logs/$symbol"));
    return jsonDecode(res.body);
  }
}
