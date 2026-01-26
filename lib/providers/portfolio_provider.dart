import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';

class PortfolioProvider extends ChangeNotifier {
  final List<PortfolioItem> _holdings = [];

  List<PortfolioItem> get holdings => _holdings;

  void buyStock({
    required String symbol,
    required String exchange,
    required int quantity,
    required double price,
    required TradeSource source,
  }) {
    final index = _holdings.indexWhere((e) => e.symbol == symbol);

    if (index != -1) {
      final item = _holdings[index];
      final totalQty = item.quantity + quantity;

      item.avgPrice =
          ((item.avgPrice * item.quantity) + (price * quantity)) / totalQty;

      item.quantity = totalQty;
      item.ltp = price;
    } else {
      _holdings.add(
        PortfolioItem(
          symbol: symbol,
          exchange: exchange,
          quantity: quantity,
          avgPrice: price,
          source: source,
        ),
      );
    }

    notifyListeners();
  }

  void updateLtp(String symbol, double price) {
    final index = _holdings.indexWhere((e) => e.symbol == symbol);
    if (index == -1) return;

    _holdings[index].ltp = price;
    notifyListeners();
  }

  void sellStock({required String symbol, required int quantity}) {
    final index = _holdings.indexWhere((e) => e.symbol == symbol);

    if (index == -1) {
      SnackBar(content: Text('SELL FAILED: Stock not in portfolio'));
      debugPrint("SELL FAILED: Stock not in portfolio");
      return;
    }

    final item = _holdings[index];

    if (quantity > item.quantity) {
      SnackBar(content: Text('SELL FAILED: Not enough quantity'));
      debugPrint("SELL FAILED: Not enough quantity");
      return;
    }

    item.quantity -= quantity;

    if (item.quantity == 0) {
      _holdings.removeAt(index);
    }

    notifyListeners();
  }
}
