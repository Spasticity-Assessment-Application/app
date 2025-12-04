import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import '../data/pose_repository.dart';
import '../domain/leg_side.dart';
import 'pose_state.dart';
import '../../../core/data/analysis_preferences_repository.dart';

class PoseCubit extends Cubit<PoseState> {
  final PoseRepository _repository;
  final AnalysisPreferencesRepository _preferencesRepository;

  PoseCubit({
    PoseRepository? repository,
    AnalysisPreferencesRepository? preferencesRepository,
  }) : _repository = repository ?? PoseRepository(),
       _preferencesRepository =
           preferencesRepository ?? AnalysisPreferencesRepository.instance,
       super(PoseInitial());

  void initializeLegSelection(String videoPath) {
    emit(
      LegSideSelection(selectedLegSide: LegSide.right, videoPath: videoPath),
    );
  }

  void updateLegSide(LegSide legSide) {
    final currentState = state;
    if (currentState is LegSideSelection) {
      emit(currentState.copyWith(selectedLegSide: legSide));
    }
  }

  Future<void> proceedToSetup() async {
    final currentState = state;
    if (currentState is LegSideSelection) {
      await setupAnalysis(legSide: currentState.selectedLegSide);
    }
  }

  Future<void> setupAnalysis({
    bool? isAdvancedMode,
    PoseModel? model,
    int? frameCount,
    double? threshold,
    LegSide? legSide,
  }) async {
    // Charger les préférences sauvegardées
    final prefs = await _preferencesRepository.loadAll();

    // Convertir le string du modèle en PoseModel enum
    PoseModel savedModel = PoseModel.mnv3l;
    if (prefs.model == 'mnv3s') {
      savedModel = PoseModel.mnv3s;
    }

    emit(
      PoseSetup(
        selectedModel: model ?? savedModel,
        frameCount: frameCount ?? prefs.frameCount,
        threshold: threshold ?? prefs.threshold,
        isAdvancedMode: isAdvancedMode ?? prefs.isAdvancedMode,
        legSide: legSide ?? LegSide.right,
      ),
    );
  }

  Future<void> updateSetup({
    PoseModel? model,
    int? frameCount,
    double? threshold,
    bool? isAdvancedMode,
    LegSide? legSide,
  }) async {
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
        legSide: LegSide.right,
      );
    }

    final newSetup = currentSetup.copyWith(
      selectedModel: model,
      frameCount: frameCount,
      threshold: threshold,
      isAdvancedMode: isAdvancedMode,
      legSide: legSide,
    );

    // Sauvegarder les nouvelles préférences
    await _preferencesRepository.saveAll(
      AnalysisPreferences(
        model: newSetup.selectedModel.name,
        frameCount: newSetup.frameCount,
        threshold: newSetup.threshold,
        isAdvancedMode: newSetup.isAdvancedMode,
      ),
    );

    emit(newSetup);
  }

  Future<void> analyzeVideo(String videoPath) async {
    if (state is! PoseSetup) {
      emit(PoseError('Analysis not configured'));
      return;
    }

    final setup = state as PoseSetup;

    try {
      print('🔵 Starting analysis with model: ${setup.selectedModel.name}');
      print('🦵 Analyzing leg side: ${setup.legSide.displayName}');

      // Charger le modèle approprié selon le côté de la jambe
      await _repository.initialize(setup.selectedModel, setup.legSide);
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

  Future<void> resetToDefaults() async {
    // Réinitialiser les préférences aux valeurs par défaut
    await _preferencesRepository.resetToDefaults();

    // Recharger l'état avec les valeurs par défaut
    await setupAnalysis(
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
