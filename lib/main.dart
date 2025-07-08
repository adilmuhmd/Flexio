// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'homeScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required


  await dotenv.load(fileName: ".env"); // ✅ loads .env from root

  runApp(SmbApp());
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
