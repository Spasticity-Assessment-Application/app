import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/primary_button.dart';
import 'package:poc/core/data/patients_repository.dart';
import 'package:poc/features/patient/domain/patient.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final TextEditingController _search = TextEditingController();
  final _repo = PatientsRepository.instance;

  List<Patient> _all = [];
  String _q = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final data = await _repo.load();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  Future<void> _addPatientFlow() async {
    final result = await context.push('/patients/add');
    if (!mounted) return;

    if (result is Map<String, String>) {
      final p = Patient(
        name: (result['name'] ?? '').trim().isEmpty
            ? 'Sans nom'
            : result['name']!.trim(),
        email: (result['email'] ?? '').trim(),
        phone: (result['phone'] ?? '').trim().isEmpty ? null : result['phone'],
        notes: (result['notes'] ?? '').trim().isEmpty ? null : result['notes'],
      );
      setState(() => _all.add(p));
      await _repo.save(_all); // persiste
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _all
        .where((p) =>
            p.name.toLowerCase().contains(_q) ||
            p.email.toLowerCase().contains(_q))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Patients'),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE6E6E6), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE6E6E6), width: 1),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = list[i];

                    // Récupère l’index d’origine dans _all (important car list est filtrée)
                    final originalIndex = _all.indexOf(p);

                    return _PatientTile(
                      name: p.name,
                      email: p.email,
                      onTap: () async {
                        // Ouvre la fiche → au retour, recharge (édit/suppr)
                        final changed = await context.push(
                          '/patients/detail',
                          extra: originalIndex,
                        );
                        if (!context.mounted) return;
                        if (changed == true) {
                          await _loadPatients();
                        } else {
                          // recharge quand même pour rester simple/fiable
                          await _loadPatients();
                        }
                      },
                    );
                  },
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              child: PrimaryButton(
                label: 'Ajouter un patient',
                onPressed: _addPatientFlow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onTap;

  const _PatientTile({
    required this.name,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFE6E6E6), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(email,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
