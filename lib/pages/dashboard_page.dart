import 'package:flutter/material.dart';
import 'package:tradelogic/pages/home_page.dart';
import 'package:tradelogic/pages/portfolio_page.dart';
import 'package:tradelogic/pages/settings_page.dart';
import 'package:tradelogic/pages/watchlist_page.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   int _currentIndex = 0;

//   final List<Widget> _pages = const [
//     DashboardPage(),
//     WatchlistPage(),
//     PortfolioPage(),
//     SettingsPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF000000),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         titleSpacing: 16,
//         title: Row(
//           children: [
//             /// Profile Avatar
//             CircleAvatar(
//               radius: 22,
//               backgroundImage: AssetImage('images/logo.png'), // replace image
//             ),

//             const SizedBox(width: 12),

//             /// Greeting + Name
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: const [
//                 Text(
//                   "GOOD MORNING",
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 12,
//                     letterSpacing: 1.2,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   "Alex Rivers",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),

//         /// Notification Icon
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1F1F1F),
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.notifications_none, color: Colors.white),
//                 onPressed: () {},
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Container(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 summaryCard(),
//                 SizedBox(height: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Market Overview",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     GridView.count(
//                       crossAxisCount: 2,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                       childAspectRatio: 1.6,
//                       children: const [
//                         MarketCard(
//                           symbol: "BTC/USD",
//                           price: "\$64,231.50",
//                           change: 1.5,
//                         ),
//                         MarketCard(
//                           symbol: "NIFTY 50",
//                           price: "22,453.10",
//                           change: -0.2,
//                         ),
//                         MarketCard(
//                           symbol: "ETH/USD",
//                           price: "\$3,421.20",
//                           change: 3.2,
//                         ),
//                         MarketCard(
//                           symbol: "AAPL",
//                           price: "\$182.40",
//                           change: 0.8,
//                         ),
//                         MarketCard(
//                           symbol: "AAPL",
//                           price: "\$182.40",
//                           change: 0.8,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),

//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.black,
//           border: Border(
//             top: BorderSide(color: Colors.white.withOpacity(0.08)),
//           ),
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//           },
//           backgroundColor: Colors.black,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: const Color(0xFF3F51B5), // indigo
//           unselectedItemColor: Colors.grey,
//           selectedFontSize: 12,
//           unselectedFontSize: 12,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_rounded),
//               label: "Dashboard",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.star_border_rounded),
//               label: "Watchlist",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.pie_chart_rounded),
//               label: "Portfolio",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings_rounded),
//               label: "Settings",
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WatchlistPage(),
    PortfolioPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            label: "Watchlist",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: "Portfolio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
