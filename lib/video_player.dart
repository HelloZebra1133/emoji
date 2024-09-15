import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoopingVideoPlayer extends StatefulWidget {
  final String videoPath;

  const LoopingVideoPlayer({super.key, required this.videoPath});

  @override
  _LoopingVideoPlayerState createState() => _LoopingVideoPlayerState();
}

class _LoopingVideoPlayerState extends State<LoopingVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI when the video is initialized
        _controller.play(); // Start playback
      }).catchError((error) {
        // Handle errors
        print('Error initializing video: $error');
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
