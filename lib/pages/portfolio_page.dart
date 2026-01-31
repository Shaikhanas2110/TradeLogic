import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tradelogic/services/api_service.dart';
import '../providers/portfolio_provider.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            /// Profile Avatar
            CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('images/logo.png'), // replace image
            ),

            const SizedBox(width: 12),

            /// Greeting + Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Portfolio",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Consumer<PortfolioProvider>(
        builder: (context, portfolio, _) {
          if (portfolio.holdings.isEmpty) {
            return const Center(
              child: Text(
                "No holdings yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return FutureBuilder(
            future: ApiService.getPortfolio(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();

              final items = snapshot.data as List;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text(
                      item["symbol"],
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      "₹${item["pnl"]}",
                      style: TextStyle(color: Colors.green),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
