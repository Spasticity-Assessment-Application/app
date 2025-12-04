import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../widgets/leg_selection/widgets.dart';

class LegSelectionPage extends StatefulWidget {
  final String videoPath;

  const LegSelectionPage({super.key, required this.videoPath});

  @override
  State<LegSelectionPage> createState() => _LegSelectionPageState();
}

class _LegSelectionPageState extends State<LegSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoseCubit>().initializeLegSelection(widget.videoPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Sélection de la jambe',
              foregroundColor: Colors.black,
              onBack: () {
                context.pop();
                context.push('/video-confirm', extra: widget.videoPath);
              },
            ),
            Expanded(
              child: BlocBuilder<PoseCubit, PoseState>(
                builder: (context, state) {
                  if (state is! LegSideSelection) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LegSelectionHeader(),
                        const SizedBox(height: 48),
                        LegSideOptions(
                          selectedLegSide: state.selectedLegSide,
                          onLegSideChanged: (legSide) {
                            context.read<PoseCubit>().updateLegSide(legSide);
                          },
                        ),
                        const SizedBox(height: 48),
                        const LegSelectionInfo(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<PoseCubit, PoseState>(
                builder: (context, state) {
                  return PrimaryButton(
                    label: 'Continuer',
                    onPressed: () {
                      context.read<PoseCubit>().proceedToSetup();
                      context.pushReplacement(
                        '/pose-setup',
                        extra: widget.videoPath,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
