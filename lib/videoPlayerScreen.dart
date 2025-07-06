

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          '--network-caching=1000',
          '--rtsp-tcp',
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
        title: Text(widget.videoUrl
            .split('/')
            .last),
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
