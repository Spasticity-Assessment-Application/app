import 'package:flutter/material.dart';
import '../../../logic/pose_state.dart';

class SummaryCard extends StatelessWidget {
  final PoseResults state;

  const SummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final totalKeypoints = state.analysisResults.fold<int>(
      0,
      (sum, result) => sum + result.keypoints.length,
    );
    final avgConfidence = _calculateAverageConfidence(state);
    final qualityLabel = _getQualityLabel(avgConfidence);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Analyse terminée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Frames analysées', '${state.analysisResults.length}'),
              _buildStat('Qualité', qualityLabel),
              _buildStat('Points détectés', '$totalKeypoints'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  double _calculateAverageConfidence(PoseResults state) {
    if (state.analysisResults.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final result in state.analysisResults) {
      for (final kp in result.keypoints) {
        totalConfidence += kp.confidence;
        count++;
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  String _getQualityLabel(double avgConfidence) {
    if (avgConfidence >= 0.8) return 'Excellente';
    if (avgConfidence >= 0.6) return 'Bonne';
    if (avgConfidence >= 0.4) return 'Moyenne';
    return 'À vérifier';
  }
}