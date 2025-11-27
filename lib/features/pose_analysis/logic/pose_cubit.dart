import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import '../data/pose_repository.dart';
import 'pose_state.dart';

class PoseCubit extends Cubit<PoseState> {
  final PoseRepository _repository;

  PoseCubit({PoseRepository? repository})
    : _repository = repository ?? PoseRepository(),
      super(PoseInitial());

  void setupAnalysis({
    bool isAdvancedMode = false,
    PoseModel? model,
    int? frameCount,
    double? threshold,
  }) {
    emit(
      PoseSetup(
        selectedModel: model ?? PoseModel.mnv3l,
        frameCount: frameCount ?? 60,
        threshold: threshold ?? 0.0,
        isAdvancedMode: isAdvancedMode,
      ),
    );
  }

  void updateSetup({
    PoseModel? model,
    int? frameCount,
    double? threshold,
    bool? isAdvancedMode,
  }) {
    PoseSetup currentSetup;
    if (state is PoseSetup) {
      currentSetup = state as PoseSetup;
    } else {
      // Si l'état n'est pas PoseSetup, créer un état par défaut
      currentSetup = PoseSetup(
        selectedModel: PoseModel.mnv3l,
        frameCount: 60,
        threshold: 0.0,
        isAdvancedMode: false,
      );
    }

    emit(
      currentSetup.copyWith(
        selectedModel: model,
        frameCount: frameCount,
        threshold: threshold,
        isAdvancedMode: isAdvancedMode,
      ),
    );
  }

  Future<void> analyzeVideo(String videoPath) async {
    if (state is! PoseSetup) {
      emit(PoseError('Analysis not configured'));
      return;
    }

    final setup = state as PoseSetup;

    try {
      print('🔵 Starting analysis with model: ${setup.selectedModel.name}');
      await _repository.initialize(setup.selectedModel);
      print('✅ Model initialized successfully');

      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        print('❌ Video file not found: $videoPath');
        emit(PoseError('Video file not found', videoPath: videoPath));
        return;
      }

      print('✅ Video file found: $videoPath');

      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      final videoDurationSeconds = duration.inSeconds;
      final videoDurationMs = duration.inMilliseconds;
      print(
        '📹 Video duration: $duration (${videoDurationSeconds}s, ${videoDurationMs}ms)',
      );

      final maxFrames = setup.frameCount;
      print(
        '📹 Will extract $maxFrames frames (forced, will repeat/extrapolate if video is short)',
      );

      final appDir = await getApplicationDocumentsDirectory();
      final framesDir = Directory(
        '${appDir.path}/pose_frames_${DateTime.now().millisecondsSinceEpoch}',
      );
      await framesDir.create(recursive: true);
      print('✅ Frames directory created: ${framesDir.path}');

      final totalFrames = maxFrames;
      final results = <FrameAnalysisResult>[];

      for (int i = 0; i < totalFrames; i++) {
        emit(PoseLoading(currentFrame: i + 1, totalFrames: totalFrames));
        print('🔄 Processing frame ${i + 1}/$totalFrames');

        // Calculate timestamp: distribute evenly over the requested duration
        final timeMs = ((i * videoDurationMs) / (totalFrames - 1)).round();
        print(
          '⏰ Frame $i timestamp: ${timeMs}ms (video duration: ${videoDurationMs}ms)',
        );

        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: framesDir.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 100,
        );

        if (thumbnailPath == null) {
          print('⚠️ Failed to extract frame $i (thumbnailPath is null)');
          continue;
        }

        print('✅ Frame $i extracted: $thumbnailPath');

        final uniqueFramePath = '${framesDir.path}/frame_$i.jpg';
        final frameFile = File(thumbnailPath);

        // Check if file exists and has content
        if (!await frameFile.exists()) {
          print('⚠️ Extracted file does not exist: $thumbnailPath');
          continue;
        }

        final fileSize = await frameFile.length();
        if (fileSize == 0) {
          print('⚠️ Extracted file is empty: $thumbnailPath');
          continue;
        }

        // Rename the file
        await frameFile.rename(uniqueFramePath);
        print('✅ Frame renamed to: $uniqueFramePath');

        final renamedFile = File(uniqueFramePath);
        final frameBytes = await renamedFile.readAsBytes();
        print('✅ Frame bytes read: ${frameBytes.length} bytes');

        if (frameBytes.isEmpty) {
          print('⚠️ Frame bytes are empty for frame $i');
          continue;
        }

        try {
          final decodedImage = img.decodeImage(frameBytes);
          if (decodedImage == null) {
            print('❌ Failed to decode image for frame $i');
            continue;
          }

          final originalWidth = decodedImage.width;
          final originalHeight = decodedImage.height;
          print('✅ Frame dimensions: ${originalWidth}x$originalHeight');

          final result = await _repository.analyzeFrame(
            frameBytes,
            i,
            originalWidth,
            originalHeight,
            setup.threshold,
            uniqueFramePath,
          );
          print(
            '✅ Frame $i analyzed: ${result.keypoints.length} keypoints detected',
          );
          results.add(result);
        } catch (e) {
          print('❌ Error analyzing frame $i: $e');
          print('Stack trace: ${StackTrace.current}');
        }
      }
      await _repository.dispose();
      print(
        '✅ Analysis complete: ${results.length} frames processed successfully out of $totalFrames requested',
      );
      print(
        '📊 Results summary: ${results.map((r) => 'Frame ${r.frameIndex}: ${r.keypoints.length} keypoints').join(', ')}',
      );

      emit(
        PoseResults(
          analysisResults: results,
          videoPath: videoPath,
          analysisCompletedAt: DateTime.now(),
          framesDirectory: framesDir.path,
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Fatal error in analyzeVideo: $e');
      print('Stack trace: $stackTrace');
      await _repository.dispose();
      emit(PoseError('Analysis failed: $e', videoPath: videoPath));
    }
  }

  void reset() {
    // Reset to setup page with default configuration
    setupAnalysis(
      isAdvancedMode: false,
      model: PoseModel.mnv3l,
      frameCount: 60,
      threshold: 0.0,
    );
  }

  @override
  Future<void> close() async {
    await _repository.dispose();
    return super.close();
  }
}
