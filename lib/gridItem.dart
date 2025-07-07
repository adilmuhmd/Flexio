import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class FileGridItem extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const FileGridItem({super.key, required this.name, required this.onTap});

  // Static cache map to store poster URLs by filename
  static final Map<String, String> _posterUrlCache = {};

  @override
  _FileGridItemState createState() => _FileGridItemState();
}

class _FileGridItemState extends State<FileGridItem> {
  String? _posterUrl;
  bool _isLoading = false;
  bool _isVideo = false;

  static final _tmdbApiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  static const String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w185';

  @override
  void initState() {
    super.initState();
    _isVideo = _isVideoFile(widget.name);

    if (_isVideo) {
      // Check if cached URL exists and set immediately
      if (FileGridItem._posterUrlCache.containsKey(widget.name)) {
        _posterUrl = FileGridItem._posterUrlCache[widget.name];
      } else {
        _fetchPoster();
      }
    }
  }

  bool _isVideoFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.mov');
  }

  String _cleanTvShowTitle(String title) {
    final match = RegExp(r'[- ]?s\d{2}e\d{2}', caseSensitive: false).firstMatch(title) ??
        RegExp(r'[- ]?s\d{4}', caseSensitive: false).firstMatch(title);

    if (match != null) {
      return title.substring(0, match.start).trim();
    }
    return title.trim();
  }

  Future<void> _fetchPoster() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final originalName = widget.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(originalName);
      final year = yearMatch?.group(0);

      String cleanTitle = originalName;
      if (yearMatch != null) {
        cleanTitle = originalName.substring(0, yearMatch.start);
      }

      cleanTitle = cleanTitle.replaceAll(RegExp(r'[\W_]+'), ' ').trim();

      if (cleanTitle.isEmpty) {
        debugPrint("⚠️ TMDb query is empty after cleaning: '${widget.name}'");
        return;
      }

      bool success = false;
      if (year != null) {
        success = await _searchTmdb(cleanTitle, year: year, isMovie: true);
      }
      if (!success) {
        success = await _searchTmdb(cleanTitle, isMovie: true);
      }
      if (!success) {
        final tvTitle = _cleanTvShowTitle(cleanTitle);
        if (tvTitle.isNotEmpty) {
          if (year != null) {
            success = await _searchTmdb(tvTitle, year: year, isMovie: false);
          }
          if (!success) {
            await _searchTmdb(tvTitle, isMovie: false);
          }
        }
      }
    } catch (e) {
      debugPrint("🔴 Exception while fetching TMDb poster for '${widget.name}': $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _searchTmdb(String query, {String? year, bool isMovie = true}) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse(
      '$_tmdbBaseUrl/search/$type?api_key=$_tmdbApiKey'
          '&query=${Uri.encodeQueryComponent(query)}'
          '${year != null ? '&year=$year' : ''}',
    );

    debugPrint("🔍 Searching TMDb $type: $query${year != null ? ' ($year)' : ''}");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;

      if (results.isNotEmpty) {
        final posterPath = results[0]['poster_path'] as String?;
        if (posterPath != null) {
          final url = '$_tmdbImageBaseUrl$posterPath';

          // Cache the URL globally for this filename
          FileGridItem._posterUrlCache[widget.name] = url;

          setState(() {
            _posterUrl = url;
          });

          debugPrint("✅ Poster found for $type '$query${year != null ? ' ($year)' : ''}': $url");
          return true;
        } else {
          debugPrint("⚠️ No poster path in $type result for '$query${year != null ? ' ($year)' : ''}'");
        }
      } else {
        debugPrint("⚠️ No results from TMDb $type for '$query${year != null ? ' ($year)' : ''}'");
      }
    } else {
      debugPrint("🔴 TMDb API error ${response.statusCode}: ${response.reasonPhrase}");
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = !widget.name.contains('.') || widget.name.endsWith('/');

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Card(
              color: Colors.black26,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                height: 200,
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3.0,
                    ),
                  )
                      : _posterUrl != null && _isVideo
                      ? CachedNetworkImage(
                    imageUrl: _posterUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(
                      isFolder ? Icons.folder : Icons.movie_creation_outlined,
                      size: 48,
                      color: isFolder ? Colors.amber : Colors.blueGrey,
                    ),
                    fadeInDuration: Duration.zero,
                  )
                      : Icon(
                    isFolder ? Icons.folder : Icons.movie_creation_outlined,
                    size: 48,
                    color: isFolder ? Colors.amber : Colors.blueGrey,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              widget.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
