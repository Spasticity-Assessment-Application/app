import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';


import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/primary_button.dart';
import 'package:poc/core/presentation/widgets/secondary_button.dart';

class VideoConfirmPage extends StatefulWidget {
  final String videoPath; 

  const VideoConfirmPage({super.key, required this.videoPath});

  @override
  State<VideoConfirmPage> createState() => _VideoConfirmPageState();
}

class _VideoConfirmPageState extends State<VideoConfirmPage> {
  late final VideoPlayerController _controller;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.isEmpty || !File(widget.videoPath).existsSync()) {
      _initError = true;
      return;
    }
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {

        _controller
          ..setLooping(true)
          ..play();
        if (mounted) setState(() {});
      }).catchError((_) {
        _initError = true;
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    if (!_initError) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Confirmation', foregroundColor: Colors.black),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildPreview(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SecondaryButton(
                    label: 'Reprendre la vidéo',
                    height: 52,
                    onPressed: () {
 
                      context.go('/camera');
                    },
                    backgroundColor: const Color(0xFFEDEDED),
                    borderColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: "Démarrer l'analyse",
                    height: 52,
                    onPressed: () {
                      context.push('/result', extra: widget.videoPath);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_initError) {
      return const Center(
        child: Text(
          "Impossible de charger la vidéo.",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio == 0
              ? 16 / 9
              : _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
