import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../domain/leg_side.dart';

enum PoseModel {
  mnv3l('assets/models/pose_model_mnv3l_float32.tflite', 384, 96),
  mnv3s('assets/models/pose_model_mnv3s_float32.tflite', 256, 64);

  final String path;
  final int inputSize;
  final int outputSize;
  const PoseModel(this.path, this.inputSize, this.outputSize);

  /// Retourne le chemin du modèle en fonction du côté de la jambe
  ///
  /// Actuellement, utilise les mêmes modèles pour les deux côtés de la jambe.
  /// Cette méthode permet une extension future pour des modèles spécialisés
  /// par côté de jambe si nécessaire.
  String getPathForLegSide(LegSide legSide) {
    // Utilise le même modèle pour les deux côtés de la jambe
    return path;
  }
}

class Keypoint {
  final String name;
  final double x;
  final double y;
  final double confidence;

  Keypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'x': x, 'y': y, 'confidence': confidence};
  }
}

class FrameAnalysisResult {
  final int frameIndex;
  final List<Keypoint> keypoints;
  final DateTime timestamp;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;

  FrameAnalysisResult({
    required this.frameIndex,
    required this.keypoints,
    required this.timestamp,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'frameIndex': frameIndex,
      'keypoints': keypoints.map((k) => k.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }
}

class PoseRepository {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  PoseModel? _currentModel;

  static const int _numKeypoints = 3;

  static const List<String> _keypointNames = ['Hanche', 'Genou', 'Cheville'];

  Future<void> initialize(PoseModel model, LegSide legSide) async {
    if (_isInitialized) {
      await dispose();
    }

    try {
      final modelPath = model.getPathForLegSide(legSide);
      print('🔵 Initializing model: $modelPath');
      print('🦵 Leg side: ${legSide.displayName}');
      print(
        '📊 Model specs: input ${model.inputSize}x${model.inputSize}, output ${model.outputSize}x${model.outputSize}',
      );
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      print('✅ Interpreter created');
      _interpreter!.allocateTensors();
      print('✅ Tensors allocated');
      _currentModel = model;
      _isInitialized = true;
      print('✅ Model initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize model: $e');
      print('Stack trace: $stackTrace');
      throw PoseException('Failed to initialize model: $e');
    }
  }

  Future<List<List<List<double>>>> preprocessFrame(Uint8List frameBytes) async {
    if (_currentModel == null) {
      throw PoseException('Model not initialized');
    }

    try {
      print('🔵 Preprocessing frame: ${frameBytes.length} bytes');
      final image = img.decodeImage(frameBytes);
      if (image == null) {
        throw PoseException('Failed to decode image');
      }
      print('✅ Image decoded: ${image.width}x${image.height}');

      final resized = img.copyResize(
        image,
        width: _currentModel!.inputSize,
        height: _currentModel!.inputSize,
        interpolation: img.Interpolation.linear,
      );
      print(
        '✅ Image resized to ${_currentModel!.inputSize}x${_currentModel!.inputSize}',
      );

      final input = List.generate(
        _currentModel!.inputSize,
        (y) => List.generate(_currentModel!.inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      );

      print('✅ Frame preprocessed successfully');
      return input;
    } catch (e, stackTrace) {
      print('❌ Preprocessing failed: $e');
      print('Stack trace: $stackTrace');
      throw PoseException('Preprocessing failed: $e');
    }
  }

  Future<List<List<List<double>>>> runInference(
    List<List<List<double>>> input,
  ) async {
    if (!_isInitialized || _interpreter == null || _currentModel == null) {
      throw PoseException('Model not initialized');
    }

    try {
      print('🔵 Running inference...');
      final inputTensor = [input];
      final output = List.generate(
        1,
        (_) => List.generate(
          _currentModel!.outputSize,
          (_) => List.generate(
            _currentModel!.outputSize,
            (_) => List<double>.filled(_numKeypoints, 0.0),
          ),
        ),
      );

      _interpreter!.run(inputTensor, output);
      print('✅ Inference complete');
      return output[0];
    } catch (e, stackTrace) {
      print('❌ Inference failed: $e');
      print('Stack trace: $stackTrace');
      throw PoseException('Inference failed: $e');
    }
  }

  List<Keypoint> postProcessHeatmaps(
    List<List<List<double>>> heatmaps,
    int originalWidth,
    int originalHeight,
    double threshold,
  ) {
    if (_currentModel == null) {
      throw PoseException('Model not initialized');
    }

    final keypoints = <Keypoint>[];

    for (int k = 0; k < _numKeypoints; k++) {
      double maxVal = 0.0;
      int maxY = 0;
      int maxX = 0;

      for (int y = 0; y < _currentModel!.outputSize; y++) {
        for (int x = 0; x < _currentModel!.outputSize; x++) {
          final val = heatmaps[y][x][k];
          if (val > maxVal) {
            maxVal = val;
            maxY = y;
            maxX = x;
          }
        }
      }

      if (maxVal >= threshold) {
        final scaledX = (maxX * originalWidth) / _currentModel!.outputSize;
        final scaledY = (maxY * originalHeight) / _currentModel!.outputSize;

        keypoints.add(
          Keypoint(
            name: _keypointNames[k],
            x: scaledX,
            y: scaledY,
            confidence: maxVal,
          ),
        );
      }
    }

    return keypoints;
  }

  Future<FrameAnalysisResult> analyzeFrame(
    Uint8List frameBytes,
    int frameIndex,
    int originalWidth,
    int originalHeight,
    double threshold,
    String imagePath,
  ) async {
    final preprocessed = await preprocessFrame(frameBytes);
    final heatmaps = await runInference(preprocessed);
    final keypoints = postProcessHeatmaps(
      heatmaps,
      originalWidth,
      originalHeight,
      threshold,
    );

    return FrameAnalysisResult(
      frameIndex: frameIndex,
      keypoints: keypoints,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      imageWidth: originalWidth,
      imageHeight: originalHeight,
    );
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _currentModel = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}

class PoseException implements Exception {
  final String message;
  PoseException(this.message);

  @override
  String toString() => 'PoseException: $message';
}
