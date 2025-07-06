// lib/screens/home_screen.dart
import 'package:flexio/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
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



  bool _isSystemShare(String name) {
    final upper = name.toUpperCase();
    return upper == 'IPC\$' ||
        upper == 'ADMIN\$' ||
        upper.startsWith('PRINT\$') ||
        upper.startsWith('.') || // hidden files
        name.trim().isEmpty;
  }


  String joinSmbPath(String base, String sub) {
    // Remove trailing slash from base if any
    var baseClean = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    // Remove leading slash from sub if any
    var subClean = sub.startsWith('/') ? sub.substring(1) : sub;
    return '$baseClean/$subClean';
  }


  Future<void> _loadFiles([String subPath = '']) async {
    setState(() {
      _loading = true;
      _files.clear();
      _status = 'Loading...';
    });

    try {
      await _saveCredentials();

      final isAbsolutePath = subPath.toLowerCase().startsWith('smb://');
      final fullPath = isAbsolutePath
          ? subPath
          : (subPath.isEmpty ? _baseUrl : '$_baseUrl$subPath');

      debugPrint('\x1B[34m➡️ Loading path: $fullPath\x1B[0m'); // Blue color for info

      _currentPath = subPath;

      final shares = await SambaBrowser.getShareList(
        fullPath,
        '',
        _userController.text.trim(),
        _passController.text,
      );

      debugPrint('\x1B[32m✅ Shares received: $shares\x1B[0m'); // Green color for success

      final rawFiles = List<String>.from(shares.cast<String>());
      debugPrint('\x1B[36m📂 Raw shares: $rawFiles\x1B[0m');

      setState(() {
        _files = rawFiles.where((fullPath) {
          // Extract share/folder name from full path
          final parts = fullPath.split('/');
          final name = parts.isNotEmpty ? parts.lastWhere((p) => p.isNotEmpty, orElse: () => '') : '';
          final isSystem = _isSystemShare(name);
          debugPrint('🔍 Checking "$fullPath" (name: "$name") => isSystem: $isSystem');
          return !isSystem;
        }).toList();

        _status = 'Found ${_files.length} items';
      });


    } catch (e, stackTrace) {
      debugPrint('\x1B[31m❌ Error loading files: $e\x1B[0m');
      debugPrint('\x1B[33m⚠️ StackTrace:\n$stackTrace\x1B[0m');
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }


  void _handleTap(String name) async {
    try {
      final lowerName = name.toLowerCase();
      final isImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.png');
      final isVideo = lowerName.endsWith('.mp4') ||
          lowerName.endsWith('.mkv') ||
          lowerName.endsWith('.avi') ||
          lowerName.endsWith('.mov');

      debugPrint('📁 Tapped item: $name');

      if (isImage) {
        final imageUrl = Uri.parse(joinSmbPath(joinSmbPath(_baseUrl, _currentPath), name));
        debugPrint('🖼️ Opening image URL: $imageUrl');
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(name)),
            body: Center(child: Image.network(imageUrl.toString())),
          ),
        ));
      } else if (isVideo) {
        // Build the full SMB URL from base, current path and filename
        final videoUrl = name;
        debugPrint('🎬 Opening video URL: $videoUrl');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: videoUrl),
          ),
        );
      } else {
        // Folder name might be absolute or relative
        final isAbsolutePath = name.toLowerCase().startsWith('smb://');
        final newPath = isAbsolutePath ? name : '$_currentPath/$name';
        debugPrint('📁 Loading folder path: $newPath');
        await _loadFiles(newPath);
      }
    } catch (e, stack) {
      debugPrint('\x1B[31m❌ Error in _handleTap: $e\x1B[0m');
      debugPrint('\x1B[33m⚠️ StackTrace: $stack\x1B[0m');
      setState(() {
        _status = 'Failed to open "$name": $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flexio'),
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
  late VlcPlayerController _vlcController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      // hwAcc: HwAcc.FULL,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          '--network-caching=1000',  // optional: tweak buffering time (ms)
          '--rtsp-tcp',              // optional for some streams
        ]),
      ),
    );

    _vlcController.addListener(() {
      if (!_isPlaying && _vlcController.value.isPlaying) {
        setState(() {
          _isPlaying = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _vlcController.stop();
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoUrl.split('/').last),
      ),
      body: Center(
        child: _isPlaying
            ? AspectRatio(
          aspectRatio: 16 / 9,
          child: VlcPlayer(
            controller: _vlcController,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
