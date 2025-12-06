import 'dart:io';
import 'package:flutter/material.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';

class SavedResultPage extends StatefulWidget {
  final String csvPath;

  const SavedResultPage({super.key, required this.csvPath});

  @override
  State<SavedResultPage> createState() => _SavedResultPageState();
}

class _SavedResultPageState extends State<SavedResultPage> {
  bool _loading = true;
  String? _error;

  late _SavedSummary _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final file = File(widget.csvPath);
      if (!await file.exists()) {
        setState(() {
          _error = "Fichier CSV introuvable.";
          _loading = false;
        });
        return;
      }

      final lines = await file.readAsLines();
      if (lines.length <= 1) {
        setState(() {
          _error = "CSV vide ou invalide.";
          _loading = false;
        });
        return;
      }

      // Frame,Keypoint,X,Y,Confidence,Timestamp
      final frameSet = <int>{};
      int totalPoints = 0;
      double sumConf = 0.0;
      int countConf = 0;

      final Map<String, List<double>> jointConf = {};

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 5) continue;

        final frame = int.tryParse(parts[0]) ?? 0;
        final keypoint = parts[1];
        final conf = double.tryParse(parts[4]) ?? 0.0;

        frameSet.add(frame);
        totalPoints++;
        sumConf += conf;
        countConf++;

        jointConf.putIfAbsent(keypoint, () => []);
        jointConf[keypoint]!.add(conf);
      }

      final framesAnalyzed = frameSet.length;
      final globalQuality =
          countConf == 0 ? 0.0 : (sumConf / countConf).clamp(0.0, 1.0) * 100.0;

      final Map<String, double> perJoint = {};
      jointConf.forEach((kp, list) {
        if (list.isEmpty) {
          perJoint[kp] = 0.0;
        } else {
          final avg = list.reduce((a, b) => a + b) / list.length;
          perJoint[kp] = (avg.clamp(0.0, 1.0) * 100.0);
        }
      });

      setState(() {
        _summary = _SavedSummary(
          framesAnalyzed: framesAnalyzed,
          totalPoints: totalPoints,
          globalQualityPercent: globalQuality,
          perJointPercent: perJoint,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur lors du chargement des résultats: $e";
        _loading = false;
      });
    }
  }


  String _qualityLabel(double percent) {
    if (percent >= 80) return 'Excellente';
    if (percent >= 60) return 'Bonne';
    if (percent >= 40) return 'Moyenne';
    return 'À vérifier';
  }

  Color _qualityColor(double percent) {
    final c = (percent / 100).clamp(0.0, 1.0);
    if (c >= 0.8) return Colors.green;
    if (c >= 0.6) return Colors.blue;
    if (c >= 0.4) return Colors.orange; // moyen = jaune/orange
    return Colors.red; // faible = rouge
  }

  String _qualityDescription(double percent) {
    final c = (percent / 100).clamp(0.0, 1.0);
    if (c >= 0.8) return 'Détection très fiable, résultats optimaux';
    if (c >= 0.6) return 'Bonne détection, résultats utilisables';
    if (c >= 0.4) {
      return 'Détection moyenne, à interpréter avec prudence';
    }
    return 'Détection faible, vérification recommandée';
  }

  String _readableJointName(String technicalName) {
    switch (technicalName.toLowerCase()) {
      case 'hanche':
        return 'Hanche';
      case 'genou':
        return 'Genou';
      case 'cheville':
        return 'Cheville';
      default:
        return technicalName
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const PageHeader(title: 'Résultats enregistrés'),
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _summary;
    final qualityLabel = _qualityLabel(s.globalQualityPercent);
    final qualityColor = _qualityColor(s.globalQualityPercent);
    final qualityDesc = _qualityDescription(s.globalQualityPercent);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
              title: 'Résultats enregistrés',
              foregroundColor: Colors.black,
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Frames analysées',
                    value: s.framesAnalyzed.toString(),
                  ),
                  _SummaryItem(
                    label: 'Qualité',
                    value: qualityLabel,
                  ),
                  _SummaryItem(
                    label: 'Points détectés',
                    value: s.totalPoints.toString(),
                  ),
                ],
              ),
            ),

            // Carte de qualité 
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: qualityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: qualityColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Qualité de la détection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            qualityLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: qualityColor,
                            ),
                          ),
                          Text(
                            '${s.globalQualityPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: qualityColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        qualityDesc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Détail par point d’articulation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...s.perJointPercent.entries.map(
                        (e) => _JointRow(
                          jointName: _readableJointName(e.key),
                          percent: e.value,
                          color: _qualityColor(e.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSummary {
  final int framesAnalyzed;
  final int totalPoints;
  final double globalQualityPercent;
  final Map<String, double> perJointPercent;

  _SavedSummary({
    required this.framesAnalyzed,
    required this.totalPoints,
    required this.globalQualityPercent,
    required this.perJointPercent,
  });
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _JointRow extends StatelessWidget {
  final String jointName;
  final double percent;
  final Color color;

  const _JointRow({
    required this.jointName,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              jointName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
