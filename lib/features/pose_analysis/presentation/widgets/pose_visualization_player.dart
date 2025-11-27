import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/pose_repository.dart';

class PoseVisualizationPlayer extends StatefulWidget {
  final List<FrameAnalysisResult> analysisResults;

  const PoseVisualizationPlayer({super.key, required this.analysisResults});

  @override
  State<PoseVisualizationPlayer> createState() =>
      _PoseVisualizationPlayerState();
}

class _PoseVisualizationPlayerState extends State<PoseVisualizationPlayer> {
  Timer? _timer;
  int _currentFrameIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (widget.analysisResults.isEmpty) return;

    setState(() => _isPlaying = true);

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      print(
        '🎬 Timer tick: currentFrameIndex = $_currentFrameIndex, totalFrames = ${widget.analysisResults.length}',
      );

      if (_currentFrameIndex >= widget.analysisResults.length - 1) {
        print('🎬 Reached end of frames, stopping playback');
        _pause();
        // Stay on the last frame instead of jumping
        return;
      }

      setState(() => _currentFrameIndex++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _seekToFrame(int frameIndex) {
    _pause();
    setState(() => _currentFrameIndex = frameIndex);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.analysisResults.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Aucune frame analysée')),
      );
    }

    if (_currentFrameIndex >= widget.analysisResults.length) {
      return const SizedBox.shrink();
    }

    final currentResult = widget.analysisResults[_currentFrameIndex];
    final imageFile = File(currentResult.imagePath);

    // Check if image file exists
    if (!imageFile.existsSync()) {
      print('⚠️ Image file does not exist: ${currentResult.imagePath}');
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Image introuvable')),
      );
    }

    print(
      '🖼️ Displaying frame $_currentFrameIndex: ${currentResult.imagePath}',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  'Visualisation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  'Frame ${_currentFrameIndex + 1}/${widget.analysisResults.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile, fit: BoxFit.contain),
                  CustomPaint(
                    painter: KeypointsPainter(
                      keypoints: currentResult.keypoints,
                      imageWidth: currentResult.imageWidth,
                      imageHeight: currentResult.imageHeight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_currentFrameIndex > 0) {
                          _seekToFrame(_currentFrameIndex - 1);
                        }
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_currentFrameIndex <
                            widget.analysisResults.length - 1) {
                          _seekToFrame(_currentFrameIndex + 1);
                        }
                      },
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _currentFrameIndex.toDouble(),
                    min: 0,
                    max: (widget.analysisResults.length - 1).toDouble(),
                    divisions: widget.analysisResults.length - 1,
                    onChanged: (value) => _seekToFrame(value.toInt()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeypointsPainter extends CustomPainter {
  final List<Keypoint> keypoints;
  final int imageWidth;
  final int imageHeight;

  KeypointsPainter({
    required this.keypoints,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    final double imageAspectRatio = imageWidth / imageHeight;
    final double canvasAspectRatio = size.width / size.height;

    double actualScaleX, actualScaleY;
    double offsetX = 0, offsetY = 0;

    if (canvasAspectRatio > imageAspectRatio) {
      actualScaleY = size.height / imageHeight;
      actualScaleX = actualScaleY;
      offsetX = (size.width - (imageWidth * actualScaleX)) / 2;
    } else {
      actualScaleX = size.width / imageWidth;
      actualScaleY = actualScaleX;
      offsetY = (size.height - (imageHeight * actualScaleY)) / 2;
    }

    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final circlePaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final kp in keypoints) {
      final displayX = kp.x * actualScaleX + offsetX;
      final displayY = kp.y * actualScaleY + offsetY;

      canvas.drawCircle(Offset(displayX, displayY), 15, circlePaint);
      canvas.drawCircle(Offset(displayX, displayY), 8, pointPaint);
    }

    if (keypoints.length >= 2) {
      final hanche = keypoints.firstWhere(
        (kp) => kp.name == 'Hanche',
        orElse: () => keypoints.first,
      );
      final genou = keypoints.firstWhere(
        (kp) => kp.name == 'Genou',
        orElse: () => keypoints.first,
      );

      final hancheDx = hanche.x * actualScaleX + offsetX;
      final hancheDy = hanche.y * actualScaleY + offsetY;
      final genouDx = genou.x * actualScaleX + offsetX;
      final genouDy = genou.y * actualScaleY + offsetY;

      canvas.drawLine(
        Offset(hancheDx, hancheDy),
        Offset(genouDx, genouDy),
        linePaint,
      );
    }

    if (keypoints.length >= 3) {
      final genou = keypoints.firstWhere(
        (kp) => kp.name == 'Genou',
        orElse: () => keypoints[1],
      );
      final cheville = keypoints.firstWhere(
        (kp) => kp.name == 'Cheville',
        orElse: () => keypoints.last,
      );

      final genouDx = genou.x * actualScaleX + offsetX;
      final genouDy = genou.y * actualScaleY + offsetY;
      final chevilleDx = cheville.x * actualScaleX + offsetX;
      final chevilleDy = cheville.y * actualScaleY + offsetY;

      canvas.drawLine(
        Offset(genouDx, genouDy),
        Offset(chevilleDx, chevilleDy),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(KeypointsPainter oldDelegate) {
    return oldDelegate.keypoints != keypoints;
  }
}
