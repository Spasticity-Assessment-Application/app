import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/oval_action_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  Future<void> _pickVideoFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (file == null) {
        return;
      }

      if (!context.mounted) return;

      context.push('/video-confirm', extra: file.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’importer la vidéo: $e')),
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

            const SizedBox(height: 16),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OvalActionButton(
                      label: 'Prendre Vidéo',
                      onTap: () => context.push('/camera'),
                      variant:
                          OvalActionButtonVariant.values.first, 
                    ),

                    const SizedBox(height: 40),

                    OvalActionButton(
                      label: 'Importer Vidéo',
                      onTap: () => _pickVideoFromGallery(context),
                      variant:
                          OvalActionButtonVariant.values.last, 
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
