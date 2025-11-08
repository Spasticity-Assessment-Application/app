import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/photo/app_photo_cubit.dart';
import 'camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final AppPhotoCubit? _appPhotoCubit;

  CameraCubit({AppPhotoCubit? appPhotoCubit})
      : _appPhotoCubit = appPhotoCubit,
        super(CameraInitial());

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;

  Future<void> initializeCamera() async {
    try {
      emit(CameraLoading());

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(CameraError(
          'No camera available. Please test on a physical device with camera.',
        ));
        return;
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false, 
      );

      await _controller!.initialize();
      emit(CameraReady(controller: _controller!, cameras: _cameras));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Permission') || msg.contains('denied')) {
        emit(CameraError(
          'Camera permission denied. Please grant camera access when prompted or check device settings.',
        ));
      } else {
        emit(CameraError('Error initializing camera: $e'));
      }
    }
  }



  Future<void> startRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      if (c.value.isRecordingVideo) return;
      await c.startVideoRecording();
      emit(VideoRecording(c));
    } catch (e) {
      emit(CameraError('Impossible de démarrer la vidéo: $e'));
    }
  }

  Future<void> stopRecordingAndSave() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      if (!c.value.isRecordingVideo) return;

      // Optionnel: émettre un état "saving" si tu veux un loader
      // emit(VideoSaving());

      final file = await c.stopVideoRecording();


      emit(VideoSaved(file.path));

      emit(CameraReady(controller: _controller!, cameras: _cameras));
    } catch (e) {
      emit(CameraError('Arrêt d’enregistrement impossible: $e'));
    }
  }


  Future<void> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      emit(CameraError('Camera is not initialized'));
      return;
    }

    try {
      emit(PhotoSaving());
      final XFile photo = await _controller!.takePicture();
      emit(PhotoTakenPreview(photo.path));
    } catch (e) {
      emit(CameraError('Error taking photo: $e'));
    }
  }

  Future<void> confirmPhoto(String tempPath) async {
    try {
      emit(PhotoSaving());
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String cachedImagePath = '${tempDir.path}/captured_photo_$timestamp.jpg';

      await File(tempPath).copy(cachedImagePath);
      await File(tempPath).delete();

      _appPhotoCubit?.setCapturedPhoto(cachedImagePath);
      emit(PhotoSaved(cachedImagePath));
    } catch (e) {
      emit(CameraError('Error saving photo: $e'));
    }
  }

  Future<void> retakePhoto() async {
    try {
      if (state is PhotoTakenPreview) {
        final tempPath = (state as PhotoTakenPreview).imagePath;
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      if (_controller != null && _controller!.value.isInitialized) {
        emit(CameraReady(controller: _controller!, cameras: _cameras));
      } else {
        await initializeCamera();
      }
    } catch (e) {
      emit(CameraError('Error returning to camera: $e'));
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _controller == null) return;

    try {
      emit(CameraLoading());

      final current = _controller!.description;
      final nextIndex = (_cameras.indexOf(current) + 1) % _cameras.length;
      final nextCamera = _cameras[nextIndex];

      await _controller!.dispose();
      _controller = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false, 
      );
      await _controller!.initialize();

      emit(CameraReady(controller: _controller!, cameras: _cameras));
    } catch (e) {
      emit(CameraError('Error switching camera: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _controller?.dispose();
    return super.close();
  }
}
