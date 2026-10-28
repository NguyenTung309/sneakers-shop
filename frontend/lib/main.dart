import 'package:flutter/material.dart';

import 'view/navigator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sneakers Shop',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Quicksand',
        colorSchemeSeed: const Color(0xFFFA2F65),
      ),
      home: const MainNavigator(),
    );
  }
}
