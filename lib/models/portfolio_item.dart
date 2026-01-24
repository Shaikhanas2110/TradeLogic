class PortfolioItem {
  final String symbol;
  final String exchange;
  final double price;
  int quantity;

  PortfolioItem({
    required this.symbol,
    required this.exchange,
    required this.price,
    required this.quantity,
  });
}

/// TEMP GLOBAL PORTFOLIO (later replace with backend)
List<PortfolioItem> portfolioItems = [];
