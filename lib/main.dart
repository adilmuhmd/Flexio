// lib/main.dart
import 'package:flutter/material.dart';

import 'homeScreen.dart';

void main() {
  runApp(const SmbApp());
}

class SmbApp extends StatelessWidget {
  const SmbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flexio',
      home: HomeScreen(),
    );
  }
}
