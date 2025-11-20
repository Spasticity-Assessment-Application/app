import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/presentation/widgets/secondary_button.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../widgets/pose_visualization_player.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:poc/core/data/patients_repository.dart';
import 'package:poc/core/data/analysis_db.dart';

class PoseResultsPage extends StatelessWidget {
  const PoseResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<PoseCubit, PoseState>(
          builder: (context, state) {
            if (state is! PoseResults) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const PageHeader(
                  title: 'Résultats',
                  foregroundColor: Colors.black,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PoseVisualizationPlayer(
                          analysisResults: state.analysisResults,
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(state),
                        const SizedBox(height: 16),
                        _buildKeypointsPreview(state),
                        const SizedBox(height: 16),
                        _buildAnalysisDetails(state),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PrimaryButton(
                        label: 'Exporter CSV',
                        onPressed: () => _exportToCsv(context, state),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Enregistrer pour un patient',
                        onPressed: () => _saveForPatient(context, state),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Nouvelle Analyse',
                        onPressed: () {
                          context.read<PoseCubit>().reset();
                          context.go('/analyse');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(PoseResults state) {
    final totalKeypoints = state.analysisResults.fold<int>(
      0,
      (sum, result) => sum + result.keypoints.length,
    );
    final avgConfidence = _calculateAverageConfidence(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Analyse Complétée',
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
              _buildStat('Frames', '${state.analysisResults.length}'),
              _buildStat('Keypoints', '$totalKeypoints'),
              _buildStat(
                'Confiance Moy.',
                '${(avgConfidence * 100).toStringAsFixed(1)}%',
              ),
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

  Widget _buildKeypointsPreview(PoseResults state) {
    if (state.analysisResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstFrame = state.analysisResults.first;

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
            'Keypoints détectés (Frame 0)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...firstFrame.keypoints.map(
            (kp) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kp.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'x: ${kp.x.toStringAsFixed(1)}, y: ${kp.y.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(kp.confidence),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(kp.confidence * 100).toStringAsFixed(0)}%',
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
    );
  }

  Widget _buildAnalysisDetails(PoseResults state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de l\'analyse',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Date',
            '${state.analysisCompletedAt.day}/${state.analysisCompletedAt.month}/${state.analysisCompletedAt.year}',
          ),
          _buildDetailRow(
            'Heure',
            '${state.analysisCompletedAt.hour.toString().padLeft(2, '0')}:${state.analysisCompletedAt.minute.toString().padLeft(2, '0')}',
          ),
          _buildDetailRow(
            'Frames analysées',
            '${state.analysisResults.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
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

  Future<void> _exportToCsv(BuildContext context, PoseResults state) async {
    try {
      final csvContent = _generateCsvContent(state);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultName = 'pose_analysis_$timestamp.csv';

      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer l\'analyse CSV',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (result == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exporté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateCsvContent(PoseResults state) {
    final buffer = StringBuffer();
    buffer.writeln('Frame,Keypoint,X,Y,Confidence,Timestamp');

    for (final result in state.analysisResults) {
      for (final kp in result.keypoints) {
        buffer.writeln(
          '${result.frameIndex},${kp.name},${kp.x},${kp.y},${kp.confidence},${result.timestamp.toIso8601String()}',
        );
      }
    }

    return buffer.toString();
  }

  Future<void> _saveForPatient(BuildContext context, PoseResults state) async {
    try {
 
      final patients = await PatientsRepository.instance.load();

      if (!context.mounted) return;

      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun patient. Ajoutez un patient avant.'),
          ),
        );
        return;
      }


      final selectedEmail = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = patients[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.email),
                  onTap: () => Navigator.of(ctx).pop(p.email),
                );
              },
            ),
          );
        },
      );

      if (selectedEmail == null) return;

      final csvContent = _generateCsvContent(state);

      final docsDir = await getApplicationDocumentsDirectory();
      final patientFolder = Directory(
        p.join(docsDir.path, 'analyses', selectedEmail),
      );
      await patientFolder.create(recursive: true);

      final filename = 'analysis_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = p.join(patientFolder.path, filename);

      final file = File(filePath);
      await file.writeAsString(csvContent);

     
      await AnalysisDb.instance.insertCsv(
        patientEmail: selectedEmail,
        csvPath: filePath,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV enregistré pour ce patient'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
