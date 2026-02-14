import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tradelogic/pages/home_page.dart';
import 'package:tradelogic/pages/portfolio_page.dart';
import 'package:tradelogic/pages/settings_page.dart';
import 'package:tradelogic/pages/watchlist_page.dart';

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
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: _pages[_currentIndex],

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.white.withOpacity(0.05), // glass effect
            selectedItemColor: const Color(0xFF6366F1), // indigo glow
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }
}
