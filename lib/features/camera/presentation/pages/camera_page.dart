import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/photo/app_photo_cubit.dart';
import '../../logic/camera_cubit.dart';
import '../../logic/camera_state.dart';
import '../widgets/photo_preview_widget.dart';
import '../widgets/camera_controls_widget.dart';
import '../widgets/camera_error_widget.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CameraCubit(appPhotoCubit: context.read<AppPhotoCubit>())
            ..initializeCamera(),
      child: const CameraView(),
    );
  }
}

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: BlocConsumer<CameraCubit, CameraState>(
        listener: (context, state) {
          if (state is CameraError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }

          else if (state is PhotoSaved) {
            context.pushReplacement('/photo-display');
          }

          else if (state is VideoSaved) {
            context.push('/video-confirm', extra: state.videoPath);
          }
        },
        builder: (context, state) {
          if (state is CameraLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (state is PhotoTakenPreview) {
            return PhotoPreviewWidget(imagePath: state.imagePath);
          }

          if (state is CameraError) {
            return CameraErrorWidget(message: state.message);
          }

          if (state is CameraReady || state is VideoRecording) {
            final controller = (state is CameraReady)
                ? state.controller
                : (state as VideoRecording).controller;

            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(controller)),
     
                CameraControlsWidget(state: state),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
      ),
    );
  }
}