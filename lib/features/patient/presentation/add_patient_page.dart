import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:poc/core/presentation/widgets/page_header.dart';
import 'package:poc/core/presentation/widgets/primary_button.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _prefilled = false; // pour éviter d’écraser la saisie à chaque rebuild

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.pop(<String, String>{
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    // Récupère d’éventuelles valeurs pour le mode édition
    final extra = GoRouterState.of(context).extra;
    final isEdit = (extra is Map && extra['mode'] == 'edit');

    // Pré-remplissage one-shot (évite d’écraser pendant que l’utilisateur tape)
    if (!_prefilled && extra is Map) {
      _nameCtrl.text  = (extra['name'] as String?)  ?? _nameCtrl.text;
      _emailCtrl.text = (extra['email'] as String?) ?? _emailCtrl.text;
      _phoneCtrl.text = (extra['phone'] as String?) ?? _phoneCtrl.text;
      _notesCtrl.text = (extra['notes'] as String?) ?? _notesCtrl.text;
      _prefilled = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: isEdit ? 'Éditer le patient' : 'Ajouter un patient'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _LabeledField(
                        label: 'Nom complet',
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Email requis';
                          final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
                          return ok ? null : 'Email invalide';
                        },
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Téléphone (optionnel)',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Notes (optionnel)',
                        controller: _notesCtrl,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PrimaryButton(
                label: isEdit ? 'Enregistrer les modifications' : 'Enregistrer',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
          ),
        ),
      ],
    );
  }
}
