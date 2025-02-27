import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.filePath});
  final String filePath;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();
    _videoPlayerController.setLooping(true);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              setState(() {
                if (_videoPlayerController.value.isPlaying) {
                  _videoPlayerController.pause();
                } else {
                  _videoPlayerController.play();
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox.expand(
              child: Transform.scale(
                scale: 2.0,
                child: Center(
                  // Rotate 90 degrees counter-clockwise
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController),
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('Error loading video'));
          }
        },
      ),
    );
  }
}
