import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';
import 'package:tradelogic/providers/portfolio_provider.dart';
import 'package:tradelogic/widget_tree.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PortfolioProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _setHighRefreshRate() async {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Failed To Set High refresh rate: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _setHighRefreshRate();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetTree();
  }
}
