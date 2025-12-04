import 'package:equatable/equatable.dart';
import '../data/pose_repository.dart';
import '../domain/leg_side.dart';

abstract class PoseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PoseInitial extends PoseState {}

class LegSideSelection extends PoseState {
  final LegSide selectedLegSide;
  final String videoPath;

  LegSideSelection({required this.selectedLegSide, required this.videoPath});

  @override
  List<Object?> get props => [selectedLegSide, videoPath];

  LegSideSelection copyWith({LegSide? selectedLegSide, String? videoPath}) {
    return LegSideSelection(
      selectedLegSide: selectedLegSide ?? this.selectedLegSide,
      videoPath: videoPath ?? this.videoPath,
    );
  }
}

class PoseSetup extends PoseState {
  final PoseModel selectedModel;
  final int frameCount;
  final double threshold;
  final bool isAdvancedMode;
  final LegSide legSide;

  PoseSetup({
    required this.selectedModel,
    required this.frameCount,
    required this.threshold,
    required this.isAdvancedMode,
    required this.legSide,
  });

  @override
  List<Object?> get props => [
    selectedModel,
    frameCount,
    threshold,
    isAdvancedMode,
    legSide,
  ];

  PoseSetup copyWith({
    PoseModel? selectedModel,
    int? frameCount,
    double? threshold,
    bool? isAdvancedMode,
    LegSide? legSide,
  }) {
    return PoseSetup(
      selectedModel: selectedModel ?? this.selectedModel,
      frameCount: frameCount ?? this.frameCount,
      threshold: threshold ?? this.threshold,
      isAdvancedMode: isAdvancedMode ?? this.isAdvancedMode,
      legSide: legSide ?? this.legSide,
    );
  }
}

class PoseLoading extends PoseState {
  final int currentFrame;
  final int totalFrames;
  final double progress;

  PoseLoading({required this.currentFrame, required this.totalFrames})
    : progress = totalFrames > 0 ? currentFrame / totalFrames : 0.0;

  @override
  List<Object?> get props => [currentFrame, totalFrames, progress];
}

class PoseResults extends PoseState {
  final List<FrameAnalysisResult> analysisResults;
  final String videoPath;
  final DateTime analysisCompletedAt;
  final String framesDirectory;

  PoseResults({
    required this.analysisResults,
    required this.videoPath,
    required this.analysisCompletedAt,
    required this.framesDirectory,
  });

  @override
  List<Object?> get props => [analysisResults, videoPath, analysisCompletedAt];
}

class PoseError extends PoseState {
  final String message;
  final String? videoPath;

  PoseError(this.message, {this.videoPath});

  @override
  List<Object?> get props => [message, videoPath];
}
