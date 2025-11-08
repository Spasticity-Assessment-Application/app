import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/primary_button.dart';
import 'package:poc/core/presentation/widgets/secondary_button.dart';
import 'package:poc/core/data/patients_repository.dart';
import 'package:poc/features/patient/domain/patient.dart';

class PatientDetailPage extends StatefulWidget {
  final int index; // index du patient dans la liste persistée
  const PatientDetailPage({super.key, required this.index});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _repo = PatientsRepository.instance;
  Patient? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.load();
    if (!mounted) return;
    if (widget.index < 0 || widget.index >= list.length) {
      context.pop(); // index invalide
      return;
    }
    setState(() {
      _patient = list[widget.index];
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (_patient == null) return;
    // On réutilise la page d’ajout comme éditeur : on lui passe les valeurs initiales
    final result = await context.push('/patients/add', extra: {
      'name': _patient!.name,
      'email': _patient!.email,
      'phone': _patient!.phone ?? '',
      'notes': _patient!.notes ?? '',
      'mode': 'edit',
    });

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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.delete(widget.index);
    if (!mounted) return;
    context.pop(true); // retourne un flag pour rafraîchir la liste
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _InfoTile(label: 'Nom', value: p.name),
                  _InfoTile(label: 'Courriel', value: p.email),
                  _InfoTile(label: 'Téléphone', value: p.phone ?? '—'),
                  _InfoTile(label: 'Notes', value: p.notes?.isNotEmpty == true ? p.notes! : '—'),

                  const SizedBox(height: 16),
                  const Text('Historique des analyses',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  // TODO: brancher ta vraie source d’historique
                  _HistoryEmpty(),
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
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: const Text('Aucune analyse pour le moment'),
    );
  }
}
