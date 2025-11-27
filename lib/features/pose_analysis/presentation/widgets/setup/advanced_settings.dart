import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pose_cubit.dart';
import '../../../logic/pose_state.dart';
import '../../../data/pose_repository.dart';
import 'setup_buttons.dart';

class AdvancedSettings extends StatelessWidget {
  const AdvancedSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseCubit, PoseState>(
      builder: (context, state) {
        if (state is! PoseSetup) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelSelector(context, state),
            const SizedBox(height: 20),
            _buildFrameCountSlider(context, state),
            const SizedBox(height: 20),
            _buildThresholdSlider(context, state),
          ],
        );
      },
    );
  }

  Widget _buildModelSelector(BuildContext context, PoseSetup state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Précision de l\'analyse',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OptionButton(
                label: 'Haute précision',
                subtitle: 'Détection plus fiable • Plus lent',
                isSelected: state.selectedModel == PoseModel.mnv3l,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(model: PoseModel.mnv3l);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OptionButton(
                label: 'Rapide',
                subtitle: 'Analyse plus rapide • Moins précis',
                isSelected: state.selectedModel == PoseModel.mnv3s,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(model: PoseModel.mnv3s);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrameCountSlider(BuildContext context, PoseSetup state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Échantillonnage vidéo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${state.frameCount} images',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Nombre d\'images analysées par seconde de vidéo',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Slider(
          value: state.frameCount.toDouble(),
          min: 1,
          max: 120,
          divisions: 119,
          activeColor: Colors.black,
          onChanged: (value) {
            context.read<PoseCubit>().updateSetup(frameCount: value.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildThresholdSlider(BuildContext context, PoseSetup state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sensibilité de détection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${(state.threshold * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Niveau minimum de confiance pour considérer une détection valide',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Slider(
          value: state.threshold,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          activeColor: Colors.black,
          onChanged: (value) {
            context.read<PoseCubit>().updateSetup(threshold: value);
          },
        ),
      ],
    );
  }
}
