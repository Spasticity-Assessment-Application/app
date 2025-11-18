import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

enum PoseModel {
  dynamic('assets/models/pose_model_dynamic.tflite'),
  float32('assets/models/pose_model_float32.tflite');

  final String path;
  const PoseModel(this.path);
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

  FrameAnalysisResult({
    required this.frameIndex,
    required this.keypoints,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'frameIndex': frameIndex,
      'keypoints': keypoints.map((k) => k.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PoseRepository {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const int _inputSize = 192;
  static const int _outputSize = 64;
  static const int _numKeypoints = 3;

  static const List<String> _keypointNames = ['Hanche', 'Genou', 'Cheville'];

  Future<void> initialize(PoseModel model) async {
    if (_isInitialized) {
      await dispose();
    }

    try {
      print('🔵 Initializing model: ${model.path}');
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(model.path, options: options);
      print('✅ Interpreter created');
      _interpreter!.allocateTensors();
      print('✅ Tensors allocated');
      _isInitialized = true;
      print('✅ Model initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize model: $e');
      print('Stack trace: $stackTrace');
      throw PoseException('Failed to initialize model: $e');
    }
  }

  Future<List<List<List<double>>>> preprocessFrame(Uint8List frameBytes) async {
    try {
      print('🔵 Preprocessing frame: ${frameBytes.length} bytes');
      final image = img.decodeImage(frameBytes);
      if (image == null) {
        throw PoseException('Failed to decode image');
      }
      print('✅ Image decoded: ${image.width}x${image.height}');

      final resized = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );
      print('✅ Image resized to ${_inputSize}x$_inputSize');

      final input = List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
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
    if (!_isInitialized || _interpreter == null) {
      throw PoseException('Model not initialized');
    }

    try {
      print('🔵 Running inference...');
      final inputTensor = [input];
      final output = List.generate(
        1,
        (_) => List.generate(
          _outputSize,
          (_) => List.generate(
            _outputSize,
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
    final keypoints = <Keypoint>[];

    for (int k = 0; k < _numKeypoints; k++) {
      double maxVal = 0.0;
      int maxY = 0;
      int maxX = 0;

      for (int y = 0; y < _outputSize; y++) {
        for (int x = 0; x < _outputSize; x++) {
          final val = heatmaps[y][x][k];
          if (val > maxVal) {
            maxVal = val;
            maxY = y;
            maxX = x;
          }
        }
      }

      if (maxVal >= threshold) {
        final scaledX = (maxX * originalWidth) / _outputSize;
        final scaledY = (maxY * originalHeight) / _outputSize;

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
    );
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
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
