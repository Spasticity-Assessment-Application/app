import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poc/features/patient/domain/patient.dart';

class PatientsRepository {
  PatientsRepository._();
  static final PatientsRepository instance = PatientsRepository._();

  static const _key = 'patients_list_v1';

  Future<List<Patient>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return <Patient>[];
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Patient.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Patient> patients) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(patients.map((p) => p.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> add(Patient p) async {
    final current = await load();
    current.add(p);
    await save(current);
  }

  Future<void> update(int index, Patient p) async {
    final current = await load();
    if (index < 0 || index >= current.length) return;
    current[index] = p;
    await save(current);
  }

  Future<void> delete(int index) async {
    final current = await load();
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    await save(current);
  }
}
