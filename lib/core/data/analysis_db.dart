import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AnalysisDb {
  AnalysisDb._();
  static final AnalysisDb instance = AnalysisDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'spasticity_app.db');

    _db = await openDatabase(
      dbPath,
      version: 3, // nouveau schéma
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS patient_csv_reports;');
        await _createSchema(db);
      },
    );

    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE patient_csv_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_email TEXT NOT NULL,
        csv_path TEXT NOT NULL,
        screenshot_path TEXT,      -- image des résultats
        summary_json TEXT,         -- si un jour on veux stocker les stats en JSON
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<int> insertCsv({
    required String patientEmail,
    required String csvPath,
    String? screenshotPath,
    String? summaryJson,
  }) async {
    final db = await database;
    return db.insert('patient_csv_reports', {
      'patient_email': patientEmail,
      'csv_path': csvPath,
      'screenshot_path': screenshotPath,
      'summary_json': summaryJson,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCsvForPatient(String email) async {
    final db = await database;
    return db.query(
      'patient_csv_reports',
      where: 'patient_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC',
    );
  }
}
