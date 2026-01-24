class Holding {
  final String symbol;
  final String exchange;
  int quantity;
  double avgPrice;
  double ltp; // live price

  Holding({
    required this.symbol,
    required this.exchange,
    required this.quantity,
    required this.avgPrice,
    required this.ltp,
  });

  double get pnl => (ltp - avgPrice) * quantity;

}
