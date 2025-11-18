import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../../data/pose_repository.dart';

class PoseSetupPage extends StatefulWidget {
  final String videoPath;

  const PoseSetupPage({super.key, required this.videoPath});

  @override
  State<PoseSetupPage> createState() => _PoseSetupPageState();
}

class _PoseSetupPageState extends State<PoseSetupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoseCubit>().setupAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PoseSetupView(videoPath: widget.videoPath);
  }
}

class PoseSetupView extends StatelessWidget {
  final String videoPath;

  const PoseSetupView({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
              title: 'Configuration Analyse',
              foregroundColor: Colors.black,
            ),
            Expanded(
              child: BlocBuilder<PoseCubit, PoseState>(
                builder: (context, state) {
                  if (state is! PoseSetup) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildModeSelector(context, state),
                        const SizedBox(height: 24),
                        if (state.isAdvancedMode) ...[
                          _buildAdvancedSettings(context, state),
                          const SizedBox(height: 24),
                        ],
                        _buildCurrentSettings(state),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Démarrer Analyse',
                onPressed: () {
                  context.read<PoseCubit>().analyzeVideo(videoPath);
                  context.push('/pose-loading');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, PoseSetup state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode d\'analyse',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Classique',
                isSelected: !state.isAdvancedMode,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(
                    isAdvancedMode: false,
                    model: PoseModel.float32,
                    frameCount: 60,
                    threshold: 0.0,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeButton(
                label: 'Avancé',
                isSelected: state.isAdvancedMode,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(isAdvancedMode: true);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, PoseSetup state) {
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
  }

  Widget _buildModelSelector(BuildContext context, PoseSetup state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modèle',
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
              child: _OptionButton(
                label: 'Dynamic',
                subtitle: '~6MB',
                isSelected: state.selectedModel == PoseModel.dynamic,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(
                    model: PoseModel.dynamic,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OptionButton(
                label: 'Float32',
                subtitle: '~22MB',
                isSelected: state.selectedModel == PoseModel.float32,
                onTap: () {
                  context.read<PoseCubit>().updateSetup(
                    model: PoseModel.float32,
                  );
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
              'Nombre de frames',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${state.frameCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
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
              'Seuil de confiance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              state.threshold.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
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

  Widget _buildCurrentSettings(PoseSetup state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration actuelle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingRow('Modèle', state.selectedModel.name),
          _buildSettingRow('Frames', '${state.frameCount}'),
          _buildSettingRow('Seuil', state.threshold.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE5E5E5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
