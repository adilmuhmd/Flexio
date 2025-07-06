// lib/screens/home_screen.dart
import 'package:flexio/preferences.dart';
import 'package:flutter/material.dart';
import 'package:samba_browser/samba_browser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'gridItem.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  List<String> _files = [];
  String _status = '';
  bool _loading = false;
  String _currentPath = '';

  String get _baseUrl {
    final raw = _hostController.text.trim();
    return raw.endsWith('/') ? raw : '$raw/';
  }

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

    if (_hostController.text.isNotEmpty) {
      _loadFiles();
    }
  }

  Future<void> _saveCredentials() async {
    await Preferences.save(
      _hostController.text.trim(),
      _userController.text.trim(),
      _passController.text,
    );
  }

  Future<void> _loadFiles([String subPath = '']) async {
    setState(() {
      _loading = true;
      _files.clear();
      _status = 'Loading...';
    });

    try {
      await _saveCredentials();
      final fullPath = subPath.isEmpty ? _baseUrl : '$_baseUrl$subPath/';
      _currentPath = subPath;
      final shares = await SambaBrowser.getShareList(
        fullPath,
        '',
        _userController.text.trim(),
        _passController.text,
      );
      setState(() {
        _files = shares.cast<String>();
        _status = 'Found ${_files.length} items';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleTap(String name) {
    final isFolder = !name.contains('.') || name.endsWith('/');
    final isImage = name.endsWith('.jpg') || name.endsWith('.png');
    final isVideo = name.endsWith('.mp4');

    if (isFolder) {
      _loadFiles('$_currentPath/$name');
    } else if (isImage) {
      final imageUrl = Uri.parse('$_baseUrl$_currentPath/$name'.replaceAll('//', '/'));
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(name)),
          body: Center(child: Image.network(imageUrl.toString())),
        ),
      ));
    } else if (isVideo) {
      final videoUrl = Uri.parse('$_baseUrl$_currentPath/$name'.replaceAll('//', '/'));
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: videoUrl.toString()),
      ));
    } else {
      final url = Uri.parse('$_baseUrl$_currentPath/$name'.replaceAll('//', '/'));
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMB File Viewer'),
        actions: [
          if (_currentPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final parts = _currentPath.split('/')..removeLast();
                _loadFiles(parts.where((e) => e.isNotEmpty).join('/'));
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_files.isEmpty) ...[
              TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'SMB Host')),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loading ? null : () => _loadFiles(),
                child: _loading ? const CircularProgressIndicator() : const Text('Load Files'),
              ),
            ],
            const SizedBox(height: 10),
            Text(_status),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                itemCount: _files.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.7),
                itemBuilder: (context, index) => FileGridItem(
                  name: _files[index],
                  onTap: () => _handleTap(_files[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Preview')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
