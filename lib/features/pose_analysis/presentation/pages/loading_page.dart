import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';

class PoseLoadingPage extends StatelessWidget {
  const PoseLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<PoseCubit, PoseState>(
          listener: (context, state) {
            print(
              '🎯 LoadingPage listener received state: ${state.runtimeType}',
            );
            if (state is PoseResults) {
              print('🎯 Navigating to results page...');
              context.pushReplacement('/pose-results');
            } else if (state is PoseError) {
              print('🎯 Error state received: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
              context.pop();
            }
          },
          child: Column(
            children: [
              const PageHeader(
                title: 'Analyse en cours',
                foregroundColor: Colors.black,
                showBack: false,
              ),
              Expanded(
                child: BlocBuilder<PoseCubit, PoseState>(
                  builder: (context, state) {
                    if (state is PoseLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: state.progress,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.black,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${(state.progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Frame ${state.currentFrame} / ${state.totalFrames}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Analyse en cours...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
