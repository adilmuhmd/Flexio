import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDbApi {
  static const _apiKey = '930468fda014966745238047b14e0346'; // 🔒 Replace with your key
  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static Future<Map<String, dynamic>?> fetchMovieDetails(String query) async {
    // Step 1: Search for the movie
    final searchUrl = '$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}';
    final searchRes = await http.get(Uri.parse(searchUrl));
    if (searchRes.statusCode != 200) return null;

    final results = json.decode(searchRes.body)['results'];
    if (results.isEmpty) return null;

    final movie = results[0];
    final movieId = movie['id'];

    // Step 2: Fetch full details including credits
    final detailUrl = '$_baseUrl/movie/$movieId?api_key=$_apiKey&append_to_response=credits';
    final detailRes = await http.get(Uri.parse(detailUrl));
    if (detailRes.statusCode != 200) return null;

    final detail = json.decode(detailRes.body);

    return {
      'title': detail['title'],
      'poster': '$_imageBaseUrl${detail['poster_path']}',
      'description': detail['overview'],
      'cast': List<String>.from(detail['credits']['cast']
          .take(6)
          .map((actor) => actor['name'] ?? '')
          .where((name) => name.isNotEmpty))
    };
  }
}
