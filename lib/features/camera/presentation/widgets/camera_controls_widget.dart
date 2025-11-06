import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/camera_cubit.dart';
import '../../logic/camera_state.dart';

class CameraControlsWidget extends StatelessWidget {
  final CameraState state;

  const CameraControlsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {

    if (state is! CameraReady && state is! VideoRecording) {
      return const SizedBox.shrink();
    }

 
    final bool isRecording = state is VideoRecording;
    final cameras = state is CameraReady ? (state as CameraReady).cameras : const <dynamic>[];


    final bool isSaving = state is VideoSaving || state is PhotoSaving;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
      
              Color(0x8A000000), 
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            if (!isRecording && cameras.length > 1)
              FloatingActionButton(
                heroTag: "switch_camera",
                onPressed: isSaving ? null : () => context.read<CameraCubit>().switchCamera(),
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: const Icon(Icons.switch_camera, color: Colors.white),
              )
            else
              const SizedBox(width: 56),

         
            FloatingActionButton.large(
              heroTag: "shutter",
              onPressed: isSaving
                  ? null
                  : () {
                      final cubit = context.read<CameraCubit>();
                      if (isRecording) {
                        cubit.stopRecordingAndSave();
                      } else {
                        cubit.startRecording();
                      }
                    },
              backgroundColor: isRecording ? Colors.red : Colors.white,
              child: isSaving
                  ? const CircularProgressIndicator()
                  : Icon(
                      isRecording ? Icons.stop : Icons.fiber_manual_record,
                      color: isRecording ? Colors.white : Colors.red,
                      size: 32,
                    ),
            ),


            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}
