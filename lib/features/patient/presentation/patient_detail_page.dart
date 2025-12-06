import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/primary_button.dart';
import 'package:poc/core/presentation/widgets/secondary_button.dart';
import 'package:poc/core/data/patients_repository.dart';
import 'package:poc/features/patient/domain/patient.dart';
import 'package:poc/core/data/analysis_db.dart';

class PatientDetailPage extends StatefulWidget {
  final int index;
  const PatientDetailPage({super.key, required this.index});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _repo = PatientsRepository.instance;
  Patient? _patient;
  bool _loading = true;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.load();
    if (!mounted) return;

    if (widget.index < 0 || widget.index >= list.length) {
      context.pop();
      return;
    }

    final p = list[widget.index];
    final history = await AnalysisDb.instance.getCsvForPatient(p.email);

    if (!mounted) return;
    setState(() {
      _patient = p;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (_patient == null) return;

    final result = await context.push(
      '/patients/add',
      extra: {
        'name': _patient!.name,
        'email': _patient!.email,
        'phone': _patient!.phone ?? '',
        'notes': _patient!.notes ?? '',
        'mode': 'edit',
      },
    );

    if (!mounted) return;
    if (result is Map<String, String>) {
      final updated = _patient!.copyWith(
        name: (result['name'] ?? '').trim(),
        email: (result['email'] ?? '').trim(),
        phone: (result['phone'] ?? '').trim().isEmpty ? null : result['phone'],
        notes: (result['notes'] ?? '').trim().isEmpty ? null : result['notes'],
      );
      await _repo.update(widget.index, updated);
      setState(() => _patient = updated);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le patient ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.delete(widget.index);
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final p = _patient!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: p.name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _InfoTile(label: 'Nom', value: p.name),
                  _InfoTile(label: 'Courriel', value: p.email),
                  _InfoTile(label: 'Téléphone', value: p.phone ?? '—'),
                  _InfoTile(
                    label: 'Notes',
                    value: p.notes?.isNotEmpty == true ? p.notes! : '—',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historique des analyses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _history.isEmpty
                      ? const _HistoryEmpty()
                      : _HistoryList(history: _history),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(label: 'Éditer le patient', onPressed: _edit),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Supprimer le patient',
                    onPressed: _delete,
                    backgroundColor: const Color(0xFFF8F8F8),
                    borderColor: const Color(0xFFE6E6E6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: const Text(
        'Aucune analyse enregistrée pour ce patient.',
        style: TextStyle(fontSize: 13, color: Colors.black54),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryList({required this.history});

  Future<void> _exportCsv(BuildContext context, String csvPath) async {
    try {
      final file = File(csvPath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fichier introuvable sur l'appareil."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bytes = await file.readAsBytes();

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter le CSV',
        fileName: p.basename(csvPath),
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (savePath == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV exporté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'export: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
        itemBuilder: (context, index) {
          final row = history[index];
          final createdAt = DateTime.tryParse(
            row['created_at'] as String? ?? '',
          );
          final subtitle = createdAt != null
              ? 'CSV du ${createdAt.toLocal()}'
              : 'CSV enregistré';
          final csvPath = row['csv_path'] as String;

          return ListTile(
            title: Text(
              'Analyse ${index + 1}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    context.push('/saved-result', extra: csvPath);
                  },
                  child: const Text(
                    'Ouvrir\nrésultats',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () => _exportCsv(context, csvPath),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
