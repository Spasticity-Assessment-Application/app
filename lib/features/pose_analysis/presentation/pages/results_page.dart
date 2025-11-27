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
import '../widgets/widgets.dart';
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
                        SummaryCard(state: state),
                        const SizedBox(height: 16),
                        QualityIndicator(state: state),
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
                        label: 'Sauvegarder pour patient',
                        onPressed: () => _saveForPatient(context, state),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Exporter données',
                        onPressed: () => _exportToCsv(context, state),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Nouvelle analyse',
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
