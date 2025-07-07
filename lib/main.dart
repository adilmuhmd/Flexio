// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'homeScreen.dart';


void main() async {
  if (dotenv.env['TMDB_API_KEY'] == null) {
    print("❌ .env file not loaded properly");
  } else {
    print("✅ TMDB_API_KEY loaded: ${dotenv.env['TMDB_API_KEY']}");
  }

  WidgetsFlutterBinding.ensureInitialized(); // Required
  await dotenv.load(); // ✅ loads .env from root

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
