import 'package:flutter/material.dart';
import 'package:flexio/preferences.dart';

class ServerCredentialsScreen extends StatefulWidget {
  final void Function(String host, String user, String pass) onCredentialsSaved;

  const ServerCredentialsScreen({super.key, required this.onCredentialsSaved});

  @override
  State<ServerCredentialsScreen> createState() => _ServerCredentialsScreenState();
}

class _ServerCredentialsScreenState extends State<ServerCredentialsScreen> {
  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await Preferences.load();
    _hostController.text = prefs['host'] ?? '';
    _userController.text = prefs['user'] ?? '';
    _passController.text = prefs['pass'] ?? '';
  }

  Future<void> _saveCredentials() async {
    setState(() => _loading = true);

    await Preferences.save(
      _hostController.text.trim(),
      _userController.text.trim(),
      _passController.text,
    );

    setState(() => _loading = false);

    widget.onCredentialsSaved(
      _hostController.text.trim(),
      _userController.text.trim(),
      _passController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Server Credentials')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'SMB Host'),
            ),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _saveCredentials,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
