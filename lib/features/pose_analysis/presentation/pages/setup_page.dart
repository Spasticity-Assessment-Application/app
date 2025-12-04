import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/presentation/widgets/secondary_button.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../../data/pose_repository.dart';
import '../../domain/leg_side.dart';
import '../widgets/widgets.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ne setup que si pas déjà en PoseSetup
      final currentState = context.read<PoseCubit>().state;
      if (currentState is! PoseSetup) {
        // Essayer de récupérer le LegSide depuis l'état précédent
        LegSide legSide = LegSide.right;
        if (currentState is LegSideSelection) {
          legSide = currentState.selectedLegSide;
        }
        await context.read<PoseCubit>().setupAnalysis(legSide: legSide);
      }
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
            PageHeader(
              title: 'Configuration Analyse',
              foregroundColor: Colors.black,
              onBack: () {
                context.pop();
                context.push('/video-confirm', extra: videoPath);
              },
            ),
            Expanded(
              child: BlocBuilder<PoseCubit, PoseState>(
                builder: (context, state) {
                  // Afficher la configuration même si l'état n'est pas strictement PoseSetup
                  PoseSetup setupState;
                  if (state is PoseSetup) {
                    setupState = state;
                  } else {
                    // Valeurs par défaut si jamais le cubit n'est pas synchronisé
                    setupState = PoseSetup(
                      selectedModel: PoseModel.mnv3l,
                      frameCount: 60,
                      threshold: 0.0,
                      isAdvancedMode: false,
                      legSide: LegSide.right,
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ModeSelector(),
                        const SizedBox(height: 24),
                        if (setupState.isAdvancedMode) ...[
                          const AdvancedSettings(),
                          const SizedBox(height: 24),
                        ],
                        CurrentSettingsSummary(state: setupState),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SecondaryButton(
                    label: 'Réinitialiser aux paramètres par défaut',
                    onPressed: () async {
                      await context.read<PoseCubit>().resetToDefaults();
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Démarrer Analyse',
                    onPressed: () async {
                      // S'assurer que l'état est PoseSetup avant de lancer l'analyse
                      final currentState = context.read<PoseCubit>().state;
                      if (currentState is! PoseSetup) {
                        // Créer un état PoseSetup par défaut si nécessaire
                        await context.read<PoseCubit>().setupAnalysis();
                      }
                      context.pushReplacement('/pose-loading');
                      context.read<PoseCubit>().analyzeVideo(videoPath);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
