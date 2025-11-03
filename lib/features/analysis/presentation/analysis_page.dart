import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/oval_action_button.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Analyse',
              foregroundColor: Colors.black,
              showBack: true,
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OvalActionButton(
                      label: 'Prendre Vidéo',
                      variant: OvalActionButtonVariant.dark,
                      onTap: () {
                        context.push('/camera-video');
                      },
                    ),

                    const SizedBox(height: 40),
                    OvalActionButton(
                      label: 'Importer Vidéo',
                      variant: OvalActionButtonVariant.light,
                      onTap: () {
                        // TODO: ouvrir la galerie vidéo
                      },
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
