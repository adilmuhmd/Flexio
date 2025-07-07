// lib/main.dart
import 'package:flutter/material.dart';

import 'homeScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  await dotenv.load(); // Load .env file
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
