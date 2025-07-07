import 'package:flexio/videoPlayerScreen.dart';
import 'package:flutter/material.dart';
import 'package:samba_browser/samba_browser.dart';
import 'gridItem.dart';
import 'movie_detail_screen.dart';

enum ContentFilter { movies, tvShows, all }

class FileBrowserScreen extends StatefulWidget {
  final String host;
  final String user;
  final String pass;

  const FileBrowserScreen({
    super.key,
    required this.host,
    required this.user,
    required this.pass,
  });

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, String>> _allFiles = [];
  ContentFilter _currentFilter = ContentFilter.all;
  bool _loading = false;
  String _status = '';
  String _currentPath = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _loadFiles();
  }

  String get _baseUrl {
    final raw = widget.host;
    return raw.endsWith('/') ? raw : '$raw/';
  }

  bool _isSystemShare(String name) {
    final upper = name.toUpperCase();
    return upper == 'IPC\$' ||
        upper == 'ADMIN\$' ||
        upper.startsWith('PRINT\$') ||
        upper.startsWith('.') ||
        name.trim().isEmpty;
  }

  bool _isMovie(String fileName) {
    final lower = fileName.toLowerCase();
    return (lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov')) &&
        !_isTvShow(fileName);
  }

  bool _isTvShow(String fileName) {
    final regex = RegExp(r's\d{2}e\d{2}', caseSensitive: false);
    return regex.hasMatch(fileName.toLowerCase());
  }

  Future<void> _loadFiles([String subPath = '']) async {
    setState(() {
      _loading = true;
      _allFiles.clear();
      _status = 'Loading...';
    });

    try {
      final isAbsolutePath = subPath.toLowerCase().startsWith('smb://');
      final fullPath = isAbsolutePath
          ? subPath
          : (subPath.isEmpty ? _baseUrl : '$_baseUrl$subPath');

      _currentPath = subPath;

      final shares = await SambaBrowser.getShareList(
        fullPath,
        '',
        widget.user,
        widget.pass,
      );

      final rawFiles = List<String>.from(shares.cast<String>());

      setState(() {
        _allFiles = rawFiles.where((fullPath) {
          final parts = fullPath.split('/');
          final name = parts.isNotEmpty
              ? parts.lastWhere((p) => p.isNotEmpty, orElse: () => '')
              : '';
          return !_isSystemShare(name);
        }).map((fullPath) {
          final name = fullPath.split('/').lastWhere(
                  (p) => p.isNotEmpty,
              orElse: () => fullPath);
          return {'name': name, 'fullPath': fullPath};
        }).toList();

        _status = 'Found ${_allFiles.length} items';
      });
    } catch (e, stackTrace) {
      setState(() {
        _status = 'Error: $e';
      });
      debugPrint('Error loading files: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _handleTap(Map<String, String> file) async {
    try {
      final name = file['name']!;
      final fullPath = file['fullPath']!;
      final lowerName = name.toLowerCase();
      final isImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.png');
      final isVideo = lowerName.endsWith('.mp4') ||
          lowerName.endsWith('.mkv') ||
          lowerName.endsWith('.avi') ||
          lowerName.endsWith('.mov');

      if (isImage) {
        final imageUrl = Uri.parse(fullPath);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(name)),
              body: Center(child: Image.network(imageUrl.toString())),
            ),
          ),
        );
      } else if (isVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(
              name: name,
              originalName: name.replaceAll(RegExp(r'\.(mp4|mkv|avi|mov)$'), ''), fullPath: '', // pass cleaned name
            ),
          ),
        );
      } else {
        final isAbsolutePath = fullPath.toLowerCase().startsWith('smb://');
        final newPath = isAbsolutePath ? fullPath : '$_currentPath/$name';
        await _loadFiles(newPath);
      }
    } catch (e, stack) {
      setState(() {
        _status = 'Failed to open: $e';
      });
      debugPrint('Error in _handleTap: $e');
      debugPrint('StackTrace: $stack');
    }
  }

  List<Map<String, String>> _filterFiles(ContentFilter filter) {
    if (filter == ContentFilter.all) return _allFiles;
    if (filter == ContentFilter.movies) {
      return _allFiles.where((file) => _isMovie(file['name']!)).toList();
    }
    return _allFiles.where((file) => _isTvShow(file['name']!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Flexio',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.black38,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
            Tab(text: 'All'),
          ],
        ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : TabBarView(
        controller: _tabController,
        children: ContentFilter.values.map((filter) {
          final visibleFiles = _filterFiles(filter);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: visibleFiles.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 0.7),
              itemBuilder: (context, index) {
                final file = visibleFiles[index];
                return FileGridItem(
                  key: ValueKey(file['fullPath']),
                  name: file['name']!,
                  onTap: () => _handleTap(file),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
