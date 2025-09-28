import 'package:flutter/material.dart';
import 'package:hackathon/product_comparison_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'App name',
      home: ProductComparisonPage(),
    );
  }
}

