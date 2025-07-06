import 'package:flutter/material.dart';
import 'package:flexio/videoPlayerScreen.dart';

class MovieDetailScreen extends StatelessWidget {
  final String name;
  final String fullPath;
  final String posterUrl; // Can be from TMDb or same SMB URL
  final String description;
  final List<String> cast;

  const MovieDetailScreen({
    super.key,
    required this.name,
    required this.fullPath,
    required this.posterUrl,
    required this.description,
    required this.cast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background poster
          Positioned.fill(
            child: Image.network(
              posterUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(name,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )),

                  const SizedBox(height: 10),

                  // Description
                  Text(description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      )),

                  const SizedBox(height: 20),

                  // Cast
                  const Text("Cast",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: cast
                        .map((actor) => Chip(
                      label: Text(actor),
                      backgroundColor: Colors.white10,
                      labelStyle: const TextStyle(color: Colors.white),
                    ))
                        .toList(),
                  ),

                  const SizedBox(height: 30),

                  // Play button
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Play"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(videoUrl: fullPath),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}
