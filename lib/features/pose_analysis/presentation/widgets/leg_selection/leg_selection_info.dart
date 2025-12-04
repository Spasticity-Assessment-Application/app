import 'package:flutter/material.dart';

class LegSelectionInfo extends StatelessWidget {
  const LegSelectionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.black54, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Le choix du côté permet d\'utiliser le modèle d\'analyse approprié pour des résultats plus précis.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
