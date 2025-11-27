import 'package:flutter/material.dart';
import '../../../logic/pose_state.dart';
import '../../../data/pose_repository.dart';

class CurrentSettingsSummary extends StatelessWidget {
  final PoseSetup state;

  const CurrentSettingsSummary({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
            'Résumé de la configuration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingRow('Précision', _getModelDisplayName(state.selectedModel)),
          _buildSettingRow('Échantillonnage', '${state.frameCount} images/sec'),
          _buildSettingRow('Sensibilité', '${(state.threshold * 100).toInt()}%'),
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

  String _getModelDisplayName(PoseModel model) {
    switch (model) {
      case PoseModel.mnv3l:
        return 'Haute précision';
      case PoseModel.mnv3s:
        return 'Rapide';
    }
  }
}