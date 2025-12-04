import 'package:flutter/material.dart';

class AnalysisHeroSection extends StatelessWidget {
  const AnalysisHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.videocam_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 40),

        const Text(
          'Nouvelle analyse',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Capturez ou importez une vidéo\npour commencer l\'analyse',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
