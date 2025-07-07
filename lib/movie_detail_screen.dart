import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flexio/videoPlayerScreen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String name;
  final String originalName;
  final String fullPath;

  const MovieDetailScreen({
    super.key,
    required this.name,
    required this.originalName,
    required this.fullPath,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  String? posterUrl;
  String? description;
  List<Map<String, dynamic>> cast = [];
  bool _loading = true;


  static final _tmdbApiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  static const _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  @override
  void initState() {
    super.initState();
    _fetchTmdbData();
  }

  Future<void> _fetchTmdbData() async {
    try {
      final originalName = widget.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(originalName);
      final year = yearMatch?.group(0);

      String cleanTitle = originalName;
      if (yearMatch != null) {
        cleanTitle = originalName.substring(0, yearMatch.start);
      }
      cleanTitle = cleanTitle.replaceAll(RegExp(r'[\W_]+'), ' ').trim();

      if (cleanTitle.isEmpty) return;

      bool success = false;
      if (year != null) {
        success = await _searchAndSetData(cleanTitle, year: year, isMovie: true);
      }
      if (!success) {
        success = await _searchAndSetData(cleanTitle, isMovie: true);
      }
      if (!success) {
        final tvTitle = _cleanTvShowTitle(cleanTitle);
        if (tvTitle.isNotEmpty) {
          if (year != null) {
            success = await _searchAndSetData(tvTitle, year: year, isMovie: false);
          }
          if (!success) {
            await _searchAndSetData(tvTitle, isMovie: false);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ TMDb fetch error: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _cleanTvShowTitle(String title) {
    final match = RegExp(r'[- ]?s\d{2}e\d{2}', caseSensitive: false).firstMatch(title);
    if (match != null) {
      return title.substring(0, match.start).trim();
    }
    return title.trim();
  }

  Future<bool> _searchAndSetData(String query, {String? year, bool isMovie = true}) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse(
      '$_tmdbBaseUrl/search/$type?api_key=$_tmdbApiKey'
          '&query=${Uri.encodeQueryComponent(query)}'
          '${year != null ? '&year=$year' : ''}',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results.isNotEmpty) {
        final result = results[0];
        final id = result['id'];
        final poster = result['poster_path'];
        final overview = result['overview'];

        setState(() {
          posterUrl = poster != null ? '$_tmdbImageBaseUrl$poster' : null;
          description = overview;
        });

        await _fetchCast(id, isMovie: isMovie);
        return true;
      }
    }
    return false;
  }

  Future<void> _fetchCast(int id, {bool isMovie = true}) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/$type/$id/credits?api_key=$_tmdbApiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final castList = data['cast'] as List<dynamic>;

      setState(() {
        cast = castList.take(10).map((actor) {
          return {
            'name': actor['name'],
            'profile_path': actor['profile_path']
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
        children: [
          // 🔲 Full screen background image
          if (posterUrl != null)
            SizedBox(
              height: size.height,
              width: size.width,
              child: CachedNetworkImage(
                imageUrl: posterUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.6),
                colorBlendMode: BlendMode.darken,
              ),
            ),

          // ✅ Foreground UI
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description ??
                        "No description available for this title.",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Cast",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: cast.map((actor) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                actor['profile_path'] != null
                                    ? CachedNetworkImageProvider(
                                    '$_tmdbImageBaseUrl${actor['profile_path']}')
                                    : null,
                                backgroundColor: Colors.grey.shade800,
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  actor['name'],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text("Play",
                          style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              videoUrl: widget.fullPath,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔙 Back Button
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
