import 'package:flutter/material.dart';
import 'package:serial/home.dart';

final naviKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: naviKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const Home(),
    );
  }
}
