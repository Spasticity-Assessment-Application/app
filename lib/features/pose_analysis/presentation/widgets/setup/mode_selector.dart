import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pose_cubit.dart';
import '../../../logic/pose_state.dart';
import '../../../data/pose_repository.dart';
import 'setup_buttons.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseCubit, PoseState>(
      builder: (context, state) {
        if (state is! PoseSetup) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type d\'analyse',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez le niveau de précision selon vos besoins cliniques',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ModeButton(
                    label: 'Standard',
                    subtitle: 'Recommandé pour la plupart des cas',
                    isSelected: !state.isAdvancedMode,
                    onTap: () {
                      context.read<PoseCubit>().updateSetup(
                        isAdvancedMode: false,
                        model: PoseModel.mnv3l,
                        frameCount: 60,
                        threshold: 0.0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModeButton(
                    label: 'Personnalisé',
                    subtitle: 'Pour ajustements spécifiques',
                    isSelected: state.isAdvancedMode,
                    onTap: () {
                      context.read<PoseCubit>().updateSetup(
                        isAdvancedMode: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
