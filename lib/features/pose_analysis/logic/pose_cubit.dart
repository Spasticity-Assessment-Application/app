import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
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
        selectedModel: model ?? PoseModel.float32,
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
    if (state is PoseSetup) {
      final currentSetup = state as PoseSetup;
      emit(
        currentSetup.copyWith(
          selectedModel: model,
          frameCount: frameCount,
          threshold: threshold,
          isAdvancedMode: isAdvancedMode,
        ),
      );
    }
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
      final appDir = await getApplicationDocumentsDirectory();
      final framesDir = Directory(
        '${appDir.path}/pose_frames_${DateTime.now().millisecondsSinceEpoch}',
      );
      await framesDir.create(recursive: true);
      print('✅ Frames directory created: ${framesDir.path}');

      final totalFrames = setup.frameCount;
      final results = <FrameAnalysisResult>[];

      for (int i = 0; i < totalFrames; i++) {
        emit(PoseLoading(currentFrame: i + 1, totalFrames: totalFrames));
        print('🔄 Processing frame ${i + 1}/$totalFrames');

        final timeMs = (i * 1000).toInt();

        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: framesDir.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 100,
        );

        if (thumbnailPath == null) {
          print('⚠️ Failed to extract frame $i');
          continue;
        }

        print('✅ Frame $i extracted: $thumbnailPath');
        final frameFile = File(thumbnailPath);
        final frameBytes = await frameFile.readAsBytes();
        print('✅ Frame bytes read: ${frameBytes.length} bytes');

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
            thumbnailPath,
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
      print('✅ Analysis complete: ${results.length} frames processed');

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
    emit(PoseInitial());
  }

  @override
  Future<void> close() async {
    await _repository.dispose();
    return super.close();
  }
}
