import 'package:flutter/material.dart';
import 'server_credentials_screen.dart';
import 'file_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _host;
  String? _user;
  String? _pass;

  void _onCredentialsSaved(String host, String user, String pass) {
    setState(() {
      _host = host;
      _user = user;
      _pass = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_host == null || _host!.isEmpty) {
      // Show credentials input first
      return ServerCredentialsScreen(onCredentialsSaved: _onCredentialsSaved);
    }

    return FileBrowserScreen(
      host: _host!,
      user: _user ?? '',
      pass: _pass ?? '',
    );
  }
}
