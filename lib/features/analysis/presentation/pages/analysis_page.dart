import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import '../widgets/widgets.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  Future<void> _pickVideoFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);

      if (file == null) {
        return;
      }

      if (!context.mounted) return;

      context.push('/video-confirm', extra: file.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'importer la vidéo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Analyse', foregroundColor: Colors.black),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AnalysisHeroSection(),

                    const SizedBox(height: 60),

                    ActionCard(
                      icon: Icons.videocam_rounded,
                      title: 'Prendre une vidéo',
                      subtitle: 'Enregistrer en temps réel',
                      onTap: () => context.push('/camera'),
                    ),

                    const SizedBox(height: 16),

                    ActionCard(
                      icon: Icons.video_library_rounded,
                      title: 'Importer une vidéo',
                      subtitle: 'Depuis votre galerie',
                      onTap: () => _pickVideoFromGallery(context),
                      isSecondary: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
