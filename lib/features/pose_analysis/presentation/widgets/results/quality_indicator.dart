import 'package:flutter/material.dart';
import '../../../logic/pose_state.dart';

class QualityIndicator extends StatelessWidget {
  final PoseResults state;

  const QualityIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final avgConfidence = _calculateAverageConfidence(state);
    final qualityColor = _getQualityColor(avgConfidence);
    final qualityLabel = _getQualityLabel(avgConfidence);
    final qualityDescription = _getQualityDescription(avgConfidence);
    final keypointsQuality = _calculateKeypointsQuality(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getQualityIcon(avgConfidence),
                color: qualityColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Qualité de la détection',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qualityLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: qualityColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qualityDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(avgConfidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: qualityColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Détail par point d\'articulation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...keypointsQuality.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getReadableKeypointName(entry.key),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getQualityColor(entry.value),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.blue;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  IconData _getQualityIcon(double confidence) {
    if (confidence >= 0.8) return Icons.check_circle;
    if (confidence >= 0.6) return Icons.thumb_up;
    if (confidence >= 0.4) return Icons.warning;
    return Icons.error;
  }

  String _getQualityDescription(double confidence) {
    if (confidence >= 0.8) return 'Détection très fiable, résultats optimaux';
    if (confidence >= 0.6) return 'Bonne détection, résultats utilisables';
    if (confidence >= 0.4) return 'Détection moyenne, à interpréter avec prudence';
    return 'Détection faible, vérification recommandée';
  }

  Map<String, double> _calculateKeypointsQuality(PoseResults state) {
    final Map<String, List<double>> keypointsConfidences = {};

    // Collecter toutes les confiances par type de keypoint
    for (final result in state.analysisResults) {
      for (final kp in result.keypoints) {
        if (!keypointsConfidences.containsKey(kp.name)) {
          keypointsConfidences[kp.name] = [];
        }
        keypointsConfidences[kp.name]!.add(kp.confidence);
      }
    }

    // Calculer la moyenne pour chaque type de keypoint
    final Map<String, double> averageQualities = {};
    keypointsConfidences.forEach((keypointName, confidences) {
      final average = confidences.reduce((a, b) => a + b) / confidences.length;
      averageQualities[keypointName] = average;
    });

    return averageQualities;
  }

  String _getReadableKeypointName(String technicalName) {
    // Convertir les noms techniques en noms compréhensibles
    switch (technicalName.toLowerCase()) {
      case 'hanche':
        return 'Hanche';
      case 'genou':
        return 'Genou';
      case 'cheville':
        return 'Cheville';
      default:
        // Pour les noms non reconnus, les rendre plus lisibles
        return technicalName.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
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